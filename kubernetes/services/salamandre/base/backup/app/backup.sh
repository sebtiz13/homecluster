#!/bin/bash
set -eo pipefail # Exit immediately on error, or if any command in a pipeline fails

# --- Variables ---

# K8s
PVC_STORAGE_CLASS=${PVC_STORAGE_CLASS:-"openebs-zfspv"}
SNAPSHOT_CLASS=${SNAPSHOT_CLASS:-"zfspv-snapclass"}
SNAPSHOT_MANGED_LABEL="backup.local/managed"
SNAPSHOT_PVC_LABEL="backup.local/pvc"
BACKUP_ENABLED_LABEL="backup.local/enabled"

# Backup logic
FULL_BACKUP_DAY=${FULL_BACKUP_DAY:-1} # 1 = Monday (ISO 8601)
S3_BUCKET_NAME=${S3_BUCKET_NAME:-"backup"}
KEEP_DAYS=${KEEP_DAYS:-3} # Keep snapshots during N days


# --- Functions ---

# Logs a message with a timestamp
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Send notification to discord
send_notification() {
  local type=$1 # "MANAGED_FAILURE" or "CRITICAL_FAILURE"
  local details=$2

  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    return
  fi

  local title color
  case "$type" in
    "MANAGED_FAILURE")
      title="⚠️ Backup partially failed"
      color=16766720 # Orange
      ;;
    "CRITICAL_FAILURE")
      title="❌ Backup failed"
      color=16711680 # Red
      details="The script stopped unexpectedly.\nReason : $details"
      ;;
    *)
      return
      ;;
  esac

  local payload
  payload=$(jq -nc --arg TITLE "$title" --arg COLOR "$color" --arg DESCRIPTION "$details" \
    '{
      "content": null,
      "embeds": [
        {
          "title": "\($TITLE)",
          "description": "\($DESCRIPTION)",
          "color": ($COLOR | tonumber)
        }
      ]
    }')

  curl -s -X POST -H 'Content-type: application/json' --data "${payload//\\\\/\\}" "$DISCORD_WEBHOOK_URL" > /dev/null
}
# Handle critical error and send it to discord
send_critical_notification() {
  local exit_code=$?
  local details="The following command failed (Code $exit_code) :\n\n\`\`\`bash\n\n$BASH_COMMAND\n\n\`\`\`"

  # Clear trap to prevent infinite loop
  trap - ERR

  log "FATAL: The script failed. exit code: $exit_code"
  send_notification "CRITICAL_FAILURE" "$details"
  exit 1
}
# Activate error trap to send failure notification
trap 'send_critical_notification' ERR


# Creates a VolumeSnapshot resource in Kubernetes.
# Usage: create_snapshot "namespace" "pvc_name" "snapshot_name"
create_snapshot() {
  local namespace=$1
  local pvc_name=$2
  local snap_name=$3

  log "Creating VolumeSnapshot $namespace/$snap_name for PVC $pvc_name."

  # Use Here-Doc to apply the VolumeSnapshot manifest dynamically
  cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: "${snap_name}"
  namespace: "${namespace}"
  labels:
    ${SNAPSHOT_MANGED_LABEL}: "true"
    ${SNAPSHOT_PVC_LABEL}: "${pvc_name}"
spec:
  volumeSnapshotClassName: ${SNAPSHOT_CLASS}
  source:
    persistentVolumeClaimName: "${pvc_name}"
EOF
}

# Waits for a VolumeSnapshot to be ready.
# Usage: wait_for_snapshot "namespace" "snapshot_name"
wait_for_snapshot() {
  local namespace=$1
  local name=$2
  log "Waiting for VolumeSnapshot $namespace/$name to be Ready..."
  if ! kubectl wait --for=jsonpath='{.status.readyToUse}=true' volumesnapshot/"$name" -n "$namespace" --timeout=60s; then
    log "ERROR: VolumeSnapshot $namespace/$name failed to become ready within the timeout."
    return 1
  fi
  return 0
}

# Fin snapshot by PVC and partial name
# Usage: find_snapshot "namespace" "pvc_name" "name_prefix"
find_snapshot() {
  local namespace=$1
  local pvc_name=$2
  local prefix=$3

  kubectl get volumesnapshots -n "$namespace" -o json | \
    jq -r --arg PVC "$pvc" --arg PREFIX "$prefix" '.items |
      sort_by(.metadata.creationTimestamp) | .[] |
      select(.spec.source.persistentVolumeClaimName == $PVC) |
      select(.metadata.name | contains($PREFIX)) |.metadata.name' |
    tail -n 1
}

# Checks if the snapshot reference (yesterday) exists on S3.
# Usage: check_s3_reference "namespace" "pvc_name" "snapshot_name_ref"
check_s3_reference() {
  local namespace=$1
  local pvc_name=$2
  local snap_ref=$3
  local s3_path="${S3_BUCKET_NAME}/${namespace}/${pvc_name}/${snap_ref}"

  # Check if file exist in s3 (filename is partial to ignore type, eg. namespace/pvc_name/date instead of namespace/pvc_name/date-full.zvol.gz)
  if mc ls -r "${s3_path}" --json 2>/dev/null | jq -e '.[]' > /dev/null; then
    return 0
  else
    return 1
  fi
}

# Finds the underlying ZFS snapshot handle and streams the data to S3.
# Usage: stream_to_s3 "namespace" "snapshot_name" "pvc_name"
stream_to_s3() {
  local namespace=$1
  local snap_name=$2
  local pvc_name=$3

  # Get the ZFS snapshot handle from the VolumeSnapshot
  local content_name zfs_handle full_zfs_snap
  content_name=$(kubectl get volumesnapshot "$snap_name" -n "$namespace" -o jsonpath='{.status.boundVolumeSnapshotContentName}' || echo "")
  zfs_handle=$(kubectl get volumesnapshotcontent "$content_name" -o jsonpath='{.status.snapshotHandle}' || echo "")
  if [ -z "$zfs_handle" ]; then
    log "ERROR: Cannot determine ZFS handle for $snap_name."
    return 1
  fi

  # Find the ZFS fullname on host
  full_zfs_snap=$(zfs list -t snapshot -H -o name 2>/dev/null | grep "$zfs_handle")
  if [ -z "$full_zfs_snap" ]; then
    log "ERROR: Cannot find matching ZFS snapshot on disk for handle $zfs_handle."
    return 1
  fi

  # Define ZFS command and filename (choose between incremental and full backup)
  local zfs_args=""
  local s3_filename_suffix=""
  local backup_message=""

  if [ "$(date +%u)" -eq "$FULL_BACKUP_DAY" ]; then
    s3_filename_suffix="-full"
    backup_message="full backup (Today is Full Backup Day)"
  else
    local yesterday_date_prefix
    yesterday_date_prefix=$(date -d "yesterday" +%Y%m%d)
    local local_yesterday_ref
    local_yesterday_ref=$(find_snapshot "$namespace" "$pvc_name" "${pvc_name}-${yesterday_date_prefix}")

    if [ -n "$local_yesterday_ref" ]; then
      if check_s3_reference "$namespace" "$pvc_name" "$local_yesterday_ref"; then
        local full_zfs_ref
        full_zfs_ref=$(zfs list -t snapshot -H -o name 2>/dev/null | grep "$local_yesterday_ref")

        if [ -n "$full_zfs_ref" ]; then
          zfs_args="-i $full_zfs_ref"
          s3_filename_suffix="-incr"
          backup_message="incremental backup from $local_yesterday_ref"
        else
          s3_filename_suffix="-full"
          backup_message="full backup (WAN: Yesterday's ZFS reference missing on host)"
        fi
      else
        s3_filename_suffix="-full"
        backup_message="full backup (WARN: S3 reference mismatch or older than yesterday)"
      fi
    else
      s3_filename_suffix="-full"
      backup_message="full backup (WARN: No local snapshot found for yesterday)"
    fi
  fi

  # Send it to S3 in compressed format
  local s3_full_path="${namespace}/${pvc_name}/${snap_name}${s3_filename_suffix}.zvol.gz"
  log "Starting ${backup_message}, then transfer it to S3 ($s3_full_path)."
  if eval "zfs send $zfs_args $full_zfs_snap" | gzip -c | mc pipe "${S3_BUCKET_NAME}/${s3_full_path}"; then
    log "Upload successful."
    return 0
  else
    log "WARNING: S3 upload failed. Local snapshot is preserved."
    return 1
  fi
}

# Applies the time-based retention policy for our own snapshots only.
# Usage: prune_snapshots "namespace" "pvc_name"
prune_snapshots() {
  local namespace=$1
  local pvc_name=$2

  log "Applying retention policy for $namespace/$pvc_name: deleting snapshots older than $KEEP_DAYS days."

  local cutoff_timestamp
  cutoff_timestamp=$(date -d "${KEEP_DAYS} days ago" +%s)

  # Find candidates for deletion (older than KEEP_DAYS)
  # shellcheck disable=SC2086
  kubectl get vs -n "$namespace" -l ${SNAPSHOT_MANGED_LABEL}=true,${SNAPSHOT_PVC_LABEL}="$pvc_name" -o json | \
  jq -r --arg CUTOFF "$cutoff_timestamp" '.items |
    .[] |
    select(.metadata.creationTimestamp != null) |
    # Select snapshots older than the cutoff time
    select((.metadata.creationTimestamp | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < ($CUTOFF | tonumber)) |
    .metadata.name' |
  while read -r name_to_delete; do
    log "  - Deleting snapshot $name_to_delete."
    kubectl delete volumesnapshot "$name_to_delete" -n "$namespace"
  done
}

# --- Main Logic ---

log "--- Starting Backup ---"

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
  log "WARNING: Webhook URL is not configured. Notification will not be sended."
  return
fi

CURRENT_DATETIME=$(date +%Y%m%d%H%M%S)
SNAPSHOT_HOUR_PREFIX=$(date +%Y%m%d%H)
GLOBAL_SUCCESS=1
FAILED_PVCs=""
TOTAL_PVC_COUNT=0

# List all PVCs matching the storage class filter
# The output format is: namespace pvc_name
PVCS_LIST=$(kubectl get pvc -A -l ${BACKUP_ENABLED_LABEL} -o jsonpath="{range .items[?(@.spec.storageClassName=='${PVC_STORAGE_CLASS}')]}{.metadata.namespace} {.metadata.name}{\"\n\"}{end}")
if [ -z "$PVCS_LIST" ]; then
  log "No PVCs found matching the filter. Exiting."
  exit 0
fi

readarray -t PVC_ARRAY <<< "$PVCS_LIST"
TOTAL_PVC_COUNT=${#PVC_ARRAY[@]}
log "Found $TOTAL_PVC_COUNT PVCs to process."
for item in "${PVC_ARRAY[@]}"; do
  read -r namespace pvc <<< "$item"
  log "--> Processing PVC: $namespace/$pvc"

  # Find most recent snapshot in the hour
  SNAP_NAME=$(find_snapshot "$namespace" "$pvc_name" "$SNAPSHOT_HOUR_PREFIX")
  if [ -n "$SNAP_NAME" ]; then
    log "Found existing snapshot for hour: $SNAP_NAME. Skipping creation."
  else
    SNAP_NAME="${pvc}-${CURRENT_DATETIME}"
    if ! create_snapshot "$namespace" "$pvc" "$SNAP_NAME"; then
      GLOBAL_SUCCESS=0
      FAILED_PVCs+="- **$namespace/$pvc**: Failed on creating snapshot.\n"
      continue
    fi
    if ! wait_for_snapshot "$namespace" "$SNAP_NAME"; then
      GLOBAL_SUCCESS=0
      FAILED_PVCs+="- **$namespace/$pvc**: Failed on waiting snapshot to be ready.\n"
      continue
    fi
  fi

  if ! stream_to_s3 "$namespace" "$SNAP_NAME" "$pvc"; then
    GLOBAL_SUCCESS=0
    FAILED_PVCs+="- **$namespace/$pvc**: Failed to send.\n"
  fi
  prune_snapshots "$namespace" "$pvc"
done

FAILED_PVC_COUNT=$(echo -n "$FAILED_PVCs" | grep -c 'Failed' || true)
log "--- Backup finished (Success: $((TOTAL_PVC_COUNT - FAILED_PVC_COUNT)), Failed: $FAILED_PVC_COUNT, Total: $TOTAL_PVC_COUNT) ---"

# Clear trap to prevent infinite loop
trap - ERR

if [ "$GLOBAL_SUCCESS" -eq 1 ]; then
  exit 0
else
  # Send failed backup to discord
  DETAILS="The job have encounter $FAILED_PVC_COUNT fail(s) on $TOTAL_PVC_COUNT PVCs.\n\nDetails:\n${FAILED_PVCs::-2}"
  send_notification "MANAGED_FAILURE" "$DETAILS"

  exit 1
fi
