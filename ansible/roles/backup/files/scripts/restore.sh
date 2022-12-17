#!/usr/bin/env bash

###
# Script constants
###
STORAGE_DIR=/var/backups

###
# Script variables
###
# Add env path
PATH=${PATH}:/usr/sbin/:/usr/local/bin
# Script variable
BACKUP_DIR=${STORAGE_DIR}/cluster
VOLUMES_DIR=${BACKUP_DIR}/volumes
ZFS_SNAPSHOTS=$(zfs list -t snapshot -o name -H)
START_TIME=$(date +%s)
CURRENT_WEEK=$(date '+%U')
# If params is pased replace `CURRENT_WEEK`
[[ -n "${1}" ]] && CURRENT_WEEK=$1

###
# Functions
###
function getDateTime() {
  date '+%Y-%m-%d %H:%M'
}

function checkSnapshot() {
  echo "${ZFS_SNAPSHOTS}" | grep -c "${1}"
}

function getSnapshots() {
  echo "${ZFS_SNAPSHOTS}" | grep "${1}"
}

function restore:snapshot() {
  local dataset
  dataset="data/${1}"
   mapfile -t SNAPSHOT_FILES < <(find "${VOLUMES_DIR}" -maxdepth 1 -type f -name "backup-${CURRENT_WEEK}-*_${2}-pvc*.zvol")
  if [[ "${#SNAPSHOT_FILES[@]}" -eq 0 ]]; then
    echo "No snapshot for ${2}"
    return;
  fi
  # Delete current snapshot (can't restore if snapshot exist)
  if [[ $(checkSnapshot "${dataset}") -gt 0 ]]; then
    echo "Remove ZFS snapshot"
    getSnapshots "${dataset}" | xargs -n1 zfs destroy
  fi
  for snapshotFile in "${SNAPSHOT_FILES[@]}"
  do
    echo "Restore \"${snapshotFile}\" to \"${dataset}\""
    zfs receive -F -v "${dataset}" < "${snapshotFile}"
  done
}

###
# Restore script
###
echo "-- Start cluster restore for \"${CURRENT_WEEK}\" - $(getDateTime) --"

echo "-- Restore PVC --"
# Get list pv list (name:podName)
PV="kubectl get pv -o jsonpath='{range .items[?(@.spec.storageClassName==\"openebs-zfspv\")]}{.metadata.name}{\":\"}{.spec.claimRef.name}{\"\n\"}{end}'"
# Dump zfs volumes
for line in $(eval "${PV}")
do
  VOLUME=$(echo "${line}" | awk -F":" '{print $1}')
  POD=$(echo "${line}" | awk -F":" '{print $2}')

  echo "${VOLUME} for pod ${POD}"
  restore:snapshot "${VOLUME}" "${POD}"
done

echo "-- End cluster restore - $(getDateTime) --"

END_TIME=$(date +%s)
ELAPSED_TIME=$(( "${END_TIME}" - "${START_TIME}" ))
echo "Elapsed Time $(date -d@"${ELAPSED_TIME}" -u +%H:%M:%S)"
