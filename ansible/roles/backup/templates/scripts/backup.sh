#!/usr/bin/env bash

###
# Script constants
###
LOG_DIR=/var/log
MINIO_DIR='{{ exec_dir }}'
BACKUP_DIR='{{ backup_dir }}'
KEEP_WEEKS='{{ keep_weeks }}'
BACKUP_BUCKET='{{ mc_bucket }}/backup'

###
# Script variables
###
# Add env path
PATH=${PATH}:/usr/sbin/:/usr/local/bin
# Script variable
VOLUMES_DIR=${BACKUP_DIR}/volumes
START_TIME=$(date +%s)
CURRENT_DATE=$(date '+%Y-%m-%d')
OLD_WEEK=$(date -d "${KEEP_WEEKS} week ago" '+%U')
CURRENT_WEEK=$(date '+%U')
PREVIOUS_DAYWEEK=$(date -d yesterday '+%w')
CURRENT_DAYWEEK=$(date '+%w')
ZFS_SNAPSHOTS=$(zfs list -t snapshot -o name -H)

###
# Functions
###
function _mkdir() {
  [[ -d "${1}" ]] || mkdir -p "${1}"
}

function getDateTime() {
  date '+%Y-%m-%d %H:%M'
}

function checkSnapshot() {
  echo "${ZFS_SNAPSHOTS}" | grep -c "${1}"
}

function buildSnapshotTag() {
  echo "backup-${1}-${2}"
}

{% raw %}
function backup:cleanOldFiles() {
  mapfile -t oldFiles < <(find "${BACKUP_DIR}" -maxdepth 2 -type f -name "backup-${OLD_WEEK}*")
  mapfile -t -O "${#oldFiles[@]}" < <(find "${LOG_DIR}" -maxdepth 1 -type f -name "backup-${OLD_WEEK}*")
  # Say if have no old files
  [[ "${#oldFiles[@]}" -eq 0 ]] && echo "No old backup"
  for oldFile in "${oldFiles[@]}"
  do
    echo "${oldFile}"
    rm "${oldFile}"
  done
}
{% endraw %}

function backup:snapshot() {
  local dataset
  local buildSnapshotTag
  local buildSnapshotName
  local fileName
  local sendArgs
  dataset="data/${1}"
  buildSnapshotTag=$(buildSnapshotTag "${CURRENT_WEEK}" "${CURRENT_DAYWEEK}")
  fileName="${VOLUMES_DIR}/${buildSnapshotTag}_${2}-${1}.zvol"
  buildSnapshotName="${dataset}@${buildSnapshotTag}"

  echo "snapshot \"${buildSnapshotName}\""
  zfs snapshot "${buildSnapshotName}"

  # DAYWEEK 0 = full backup
  if [[ ${CURRENT_DAYWEEK} -gt 0 ]]; then
    previousSnapshot="${dataset}@$(buildSnapshotTag "${CURRENT_WEEK}" "${PREVIOUS_DAYWEEK}")"
    # Check if previous snapshot exist for incremental
    if [[ $(checkSnapshot "${previousSnapshot}") -eq 1 ]]; then
      sendArgs=(-i "${previousSnapshot}")
    fi
  fi
  echo "send \"${buildSnapshotName}\" with \"${sendArgs[*]}\""
  zfs send -v "${sendArgs[@]}" "${buildSnapshotName}" > "${fileName}"
}

###
# Backup script
###
# Create backups directories
_mkdir "${BACKUP_DIR}"
_mkdir "${VOLUMES_DIR}"

echo "-- Start cluster backup - $(getDateTime) --"

echo "-- Remove old backup --"
backup:cleanOldFiles

echo "-- Backup PVC --"
# Get list pv list (name:podName)
PV="kubectl get pv -o jsonpath='{range .items[?(@.spec.storageClassName==\"openebs-zfspv\")]}{.metadata.name}{\":\"}{.spec.claimRef.name}{\"\n\"}{end}'"

# Dump zfs volumes
for line in $(eval "${PV}")
do
  VOLUME=$(echo "${line}" | awk -F":" '{print $1}')
  POD=$(echo "${line}" | awk -F":" '{print $2}')

  echo "${VOLUME} for pod ${POD}"
  backup:snapshot "${VOLUME}" "${POD}"
done

# Dump database on full backup (to ensure minimum backup of database)
echo "-- Backup database --"
SQL_FILENAME="$(buildSnapshotTag "${CURRENT_WEEK}" "${CURRENT_DAYWEEK}")-database-${CURRENT_DATE}.sql"
echo "Dump all to ${SQL_FILENAME}"
sudo -u postgres pg_dumpall > "${BACKUP_DIR}/${SQL_FILENAME}"

echo "-- Sync backup to minio --"
"${MINIO_DIR}"/mc --config-dir "${MINIO_DIR}"/.mc --debug mirror "${BACKUP_DIR}" "${BACKUP_BUCKET}"

echo "-- End cluster backup - $(getDateTime) --"

END_TIME=$(date +%s)
ELAPSED_TIME=$(( "${END_TIME}" - "${START_TIME}" ))
echo "Elapsed Time $(date -d@"${ELAPSED_TIME}" -u +%H:%M:%S)"
