#!/bin/bash

###
# Script constants
###
LOG_DIR=/var/log/backup-cluster
BACKUP_DIR=/var/backups/kubernetes
EXEC_DIR=/opt/backup-cluster
LOGS_KEEP_WEEKS=6
FILES_KEEP_WEEKS=2
BACKUP_PVC_BUCKET=baku/backup-salamandre-pvc
BACKUP_DB_BUCKET=baku/backup-salamandre-pg

OPENEBS_NAMESPACE=kube-system
DATABASE_NAMESPACE=database
DATABASE_CLUSTER_NAME="postgres16"
DATABASE_POD_NAME="${DATABASE_CLUSTER_NAME}-1"

###
# Script variables
###
if [ "$1" == "cron" ]; then
  IS_CRON_RUN=1
  DATETIME_FORMAT=+%Y%m%d%H0000
else
  DATETIME_FORMAT=+%Y%m%d%H%M%S
fi

# Script variable
START_TIME=$(date +%s)
CURRENT_DAYWEEK=$(date +%w)
CURRENT_DATETIME=$(date $DATETIME_FORMAT)
YESTERDAY_DATETIME=$(date -d "yesterday" $DATETIME_FORMAT)
_LOGS_KEEP_TIME="last-sunday - $LOGS_KEEP_WEEKS week"
_FILES_KEEP_TIME="last-sunday - $FILES_KEEP_WEEKS week"

ZFS_SNAPSHOTS=$(zfs list -t snapshot -o name -H)

PVC_CONDITION='?(@.spec.storageClassName=="openebs-zfspv")' # TODO: change to label/annotation
PVC_OUTPUT_NAME='{.metadata.namespace}{":"}{.metadata.name}' # Format: namespace:name

# Check if database need to be dump
if [ -n "$IS_CRON_RUN" ] || [[ $CURRENT_DAYWEEK -gt 0 ]]; then
  DATABASE_NEED_DUMP=1
fi

###
# Functions
###
# usage: log "function" "message"
function log() {
  echo "[$1] $2"
}

function checkSnapshot() {
  echo "${ZFS_SNAPSHOTS}" | grep -c "${1}"
}

# usage: wait_for_zfsSnapshot "name"
function wait_for_zfsSnapshot() {
  local max_wait_secs=30
  local interval_secs=2
  local start_time
  local current_time
  start_time=$(date +%s)

  while true; do
    current_time=$(date +%s)
    if (((current_time - start_time) > max_wait_secs)); then
      log "wait_for_zfsSnapshot" "Waited for zfs snapshot in namespace \"$OPENEBS_NAMESPACE\" with name \"$2\" to exist for $max_wait_secs seconds without luck. Returning with error."
      return 1
    fi

    if kubectl -n $OPENEBS_NAMESPACE get zfssnapshot "$2" --request-timeout "5s" &> /dev/null; then
      break
    else
      sleep $interval_secs
    fi
  done
  kubectl wait --for=jsonpath='{.status.state}'=Ready -n $OPENEBS_NAMESPACE zfssnapshots "$2" > /dev/null
}

# Prune cron logs files
function backup:pruneLogs() {
  mapfile -t oldFiles < <(find "${LOG_DIR}" -maxdepth 1 -type f -name "cron-*.log" -not -newermt "$_LOGS_KEEP_TIME")
  # Say if have no old files
  [[ "${#oldFiles[@]}" -eq 0 ]] && log "backup:pruneLogs" "No old logs need to be deleted"
  for file in "${oldFiles[@]}"
  do
    if [ -f "$file" ]; then
      rm "$file" > /dev/null
      log "backup:pruneLogs" "File \"$file\" as been deleted"
    fi
  done
}
# Prune ZFS snapshot files (".zvol.gz")
function backup:prunePVCFiles() {
  mapfile -t files < <(find "${BACKUP_DIR}/pvc" -maxdepth 2 -type f -name "*.zvol.gz" -not -newermt "$_FILES_KEEP_TIME")

  [[ "${#files[@]}" -eq 0 ]] && log "backup:prunePVCFiles" "No files need to be deleted"
  for file in "${files[@]}"
  do
    if [ -f "$file" ]; then
      rm "$file" > /dev/null
      log "backup:prunePVCFiles" "File \"$file\" as been deleted"
    fi
  done
}
# Prune database files (".sql.gz")
function backup:pruneDBFiles() {
  mapfile -t files < <(find "${BACKUP_DIR}/db" -maxdepth 1 -type f -name "*.sql.gz" -not -newermt "$_FILES_KEEP_TIME")

  [[ "${#files[@]}" -eq 0 ]] && log "backup:pruneDBFiles" "No files need to be deleted"
  for file in "${files[@]}"
  do
    if [ -f "$file" ]; then
      rm "$file" > /dev/null
      log "backup:pruneDBFiles" "File \"$file\" as been deleted"
    fi
  done
}

# Prune snapshot (VolumeSnapshot kubernetes resources)
# usage: backup:pruneSnapshots "namespace" "pvcName"
function backup:pruneSnapshots() {
  local expiredDay
  local cmdArgs
  expiredDay=$(date -d "${FILES_KEEP_WEEKS} week ago" $DATETIME_FORMAT)
  cmdArgs=(-n "$1" "${2}-$expiredDay")

  # Check if snapshot exist
  if [ -z "$(kubectl get vs --ignore-not-found -o jsonpath='{.metadata.uid}' "${cmdArgs[@]}")" ]; then
    return 0
  fi

  log "backup:pruneSnapshots" "Remove expired snapshots for pvc ${1}/$2"
  if kubectl delete vs "${cmdArgs[@]}" > /dev/null; then
    log "backup:pruneSnapshots" "Snapshot ${2}-$expiredDay for pvc ${1}/$2 as been deleted"
  else
    log "backup:pruneSnapshots" "ERROR: Failed to delete snapshot for pvc ${1}/$2"
  fi
}

# Create Persistent Volume snapshot
# usage: backup:snapshot "namespace" "pvcName"
# return (in variables):
# - $vSnapshotName: snapshot name
# - $vlSnapshotUid: snapshot uid
function backup:snapshot() {
  vlSnapshotName="${2}-$CURRENT_DATETIME"

  log "backup:snapshot" "Create snapshot for pvc ${1}/$2"

  # Create template
  tmp=/tmp/backup-snap.$$
  # shellcheck disable=SC2064
  trap "rm -f $tmp; exit 1" 0 1 2 3 SIGPIPE 15  # aka EXIT HUP INT QUIT PIPE TERM
  sed -e "s/%name%/$vlSnapshotName/g" -e "s/%namespace%/$1/g" \
    -e "s/%pvc_name%/$2/g" "$EXEC_DIR/snapshot_template.yaml" > $tmp

  # Apply it
  kubectl apply -f "$tmp" >/dev/null

  # Remove tmp file and trap
  rm -f $tmp
  trap 0

  vlSnapshotUid=$(kubectl get vs -o jsonpath='{.metadata.uid}' -n "$1" "$vlSnapshotName")
  if wait_for_zfsSnapshot "$1" "snapshot-$vlSnapshotUid"; then
    log "backup:snapshot" "Snapshot for pvc ${1}/${2} as been created with name ${vlSnapshotName} (UID: ${vlSnapshotUid})"
  else
    log "backup:snapshot" "ERROR: Failed to create snapshot for pvc ${1}/${2}. Please check status with \"kubectl describe zfssnapshot -n $OPENEBS_NAMESPACE snapshot-$vlSnapshotUid\""
    return 1
  fi
}

# Export ZFS snapshot to an ".zvol.gz" file
# usage: backup:zfsExport "namespace" "pvcName" "vlSnapshotName" "vlSnapshotUid"
function backup:zfsExport() {
  local dataset
  local snapshotName
  local fileSuffix
  local logMessage
  local elapsedTime
  local sendArgs
  local filepath

  dataset="data/$(kubectl get pvc -o jsonpath='{.spec.volumeName}' -n "$1" "$2")"
  snapshotName="${dataset}@snapshot-$4"
  fileSuffix="-full"
  logMessage="Full send snapshot $3 ($snapshotName)"
  elapsedTime=$(date +%s)

  # Make incremental export if not dayw wek 0
  if [[ $CURRENT_DAYWEEK -gt 0 ]]; then
    local previousSnapshotUid
    local previousSnapshot
    previousSnapshotUid=$(kubectl get vs --ignore-not-found -o jsonpath='{.metadata.uid}' -n "$1" "${2}-$YESTERDAY_DATETIME")
    previousSnapshot="${dataset}@snapshot-$previousSnapshotUid"

    # Check if previous snapshot exist for incremental
    if [[ $(checkSnapshot "${previousSnapshot}") -eq 1 ]]; then
      sendArgs=(-i "${previousSnapshot}")
      fileSuffix="-incr"
      logMessage="Incremental send snapshot $3 (from $previousSnapshot to $snapshotName)"
    fi
  fi

  log "backup:zfsExport" "$logMessage"

  # File path format: pvc/$namespace/$pvcName$date{%Y%m%d%H%M%S}-[full/incr]
  filepath="${BACKUP_DIR}/pvc/${1}/${3}${fileSuffix}.zvol.gz"
  mkdir -p "$(dirname "$filepath")"
  zfs send "${sendArgs[@]}" "$snapshotName" | gzip > "$filepath"

  elapsedTime=$(($(date +%s) - elapsedTime))
  log "backup:zfsExport" "Snapshot $3 as been sended to \"$filepath\" in aprox $elapsedTime seconds"
}

# Dump database to an ".sql.gz" file
function backup:dbDump() {
  local elapsedTime
  local filepath
  elapsedTime=$(date +%s)
  filepath="${BACKUP_DIR}/db/${DATABASE_CLUSTER_NAME}-${CURRENT_DATETIME}.sql"

  log "backup:dbDump" "Dump database"
  kubectl exec -n "${DATABASE_NAMESPACE}" "${DATABASE_POD_NAME}" -- pg_dumpall | gzip > "$filepath"

  elapsedTime=$(($(date +%s) - elapsedTime))
  log "backup:dbDump" "Database as been dumped to \"$filepath\" in aprox $elapsedTime seconds"
}

###
# Backup script
###
# Create backups directories
echo "-- Start backup --"
mkdir -p "${BACKUP_DIR}/pvc"
mkdir -p "${BACKUP_DIR}/db"

# Clean old logs
if [ -z "$IS_CRON_RUN" ]; then
  echo "-- Clean old backup logs --"
  backup:pruneLogs
  backup:prunePVCFiles
  backup:pruneDBFiles
fi

echo "-- Backup PVC --"
# List volumes claim want backup
log "_" "List volumes"
volumesClaim="kubectl get pvc -A -o jsonpath='{range .items[${PVC_CONDITION}]}${PVC_OUTPUT_NAME}{\"\n\"}{end}'"

# Dump zfs volumes
for line in $(eval "${volumesClaim}")
do
  namespace=$(echo "${line}" | awk -F":" '{print $1}')
  name=$(echo "${line}" | awk -F":" '{print $2}')

  # Clean old snapshots
  if [ -z "$IS_CRON_RUN" ]; then
    backup:pruneSnapshots "$namespace" "$name"
  fi

  if backup:snapshot "$namespace" "$name"; then
    backup:zfsExport "$namespace" "$name" "$vlSnapshotName" "$vlSnapshotUid"
  fi
done

if [ -n "$DATABASE_NEED_DUMP" ]; then
  echo "-- Dump database --"
  backup:dbDump
fi

echo "-- Sync backup to minio --"
"${EXEC_DIR}/mc" --config-dir "${EXEC_DIR}/.mc" mirror "${BACKUP_DIR}/pvc" "${BACKUP_PVC_BUCKET}"
if [ -n "$DATABASE_NEED_DUMP" ]; then
  "${EXEC_DIR}/mc" --config-dir "${EXEC_DIR}/.mc" mirror "${BACKUP_DIR}/db" "${BACKUP_DB_BUCKET}/dump"
fi

END_TIME=$(date +%s)
ELAPSED_TIME=$(date -d@$((END_TIME - START_TIME)) -u +%H:%M:%S)
echo "-- End cluster backup. Elapsed Time: $ELAPSED_TIME --"
