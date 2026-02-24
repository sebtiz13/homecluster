#!/bin/bash
set -eo pipefail # Exit immediately on error, or if any command in a pipeline fails

# --- Variables ---

LOG_DIR="/app/logs"

# K8s
PVC_STORAGE_CLASS=${PVC_STORAGE_CLASS:-"openebs-zfspv"}
SNAPSHOT_CLASS=${SNAPSHOT_CLASS:-"zfspv-snapclass"}
SNAPSHOT_MANGED_LABEL="backup.local/managed"
SNAPSHOT_PVC_LABEL="backup.local/pvc"
BACKUP_ENABLED_LABEL="backup.local/enabled"
CNPG_CLUSTER_NAME="postgres16"

# Backup logic
FULL_BACKUP_DAY=${FULL_BACKUP_DAY:-1} # 1 = Monday (ISO 8601)
S3_BUCKET_NAME=${S3_BUCKET_NAME:-"backup"}
KEEP_DAYS=${KEEP_DAYS:-3} # Keep snapshots during N days
FORCE_FULL_BACKUP=${FORCE_FULL_BACKUP:"false"}

# Retries
UPLOAD_RETRIES=${UPLOAD_RETRIES:-3}
UPLOAD_RETRY_DELAY=${UPLOAD_RETRY_DELAY:-10}

# --- End Variables ---

mkdir -p "$LOG_DIR"
if [ -n "$MANUAL_DATE" ]; then
  LOG_SUFFIX="manual"
fi
# Tee: logs to PVC file AND stdout (for kubectl logs)
exec &> >(tee -a "$LOG_DIR/$(date +%Y%m%d-%H%M%S)-${LOG_SUFFIX:-"cron"}.log")

# Logs a message with a timestamp
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Allow customizing the date (format YYYYMMDD)
if [ -n "$MANUAL_DATE" ]; then
  TODAY_YMD="$MANUAL_DATE"
  log "INFO: Using MANUAL_DATE=$TODAY_YMD for all operations."
else
  TODAY_YMD=$(date +%Y%m%d)
  log "INFO: Using CRON_DATE=$TODAY_YMD for all operations."
fi

# --- Functions ---

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
# shellcheck disable=SC2329
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

# Check if date is valid with "YYYYMMDD" format.
# Usage: validate_date_format "date"
validate_date_format() {
  local date_str="$1"

  # Check if format is valid
  local regex='^([0-9]{4})([0-9]{2})([0-9]{2})$'
  if [[ ! "$date_str" =~ $regex ]]; then
    return 1
  fi

  # Check if values is valid
  local year="${BASH_REMATCH[1]}"
  local month="${BASH_REMATCH[2]}"
  local day="${BASH_REMATCH[3]}"
  local canonical_date="${year}-${month}-${day}"
  if ! date -d "$canonical_date" >/dev/null 2>&1; then
    return 1
  fi

  return 0
}

# Creates a VolumeSnapshot resource in Kubernetes.
# Usage: create_snapshot "namespace" "pvc_name" "snapshot_name"
create_snapshot() {
  local namespace=$1
  local pvc_name=$2
  local snap_name=$3

  log "Creating VolumeSnapshot $namespace/$snap_name for PVC $pvc_name."

  # Use Here-Doc to apply the VolumeSnapshot manifest dynamically
  cat <<EOF | kubectl apply -f - >/dev/null
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
  if ! kubectl wait --for=jsonpath='{.status.readyToUse}=true' volumesnapshot/"$name" -n "$namespace" --timeout=60s >/dev/null; then
    log "ERROR: VolumeSnapshot $namespace/$name failed to become ready within the timeout."
    return 1
  fi
  return 0
}

# Creates a CNPG backup
# Usage: create_cnpg_backup "namespace" "cluster_name" "backup_name"
create_cnpg_backup() {
  local namespace=$1
  local cluster_name=$2
  local backup_name=$3

  log "CNPG: Creating Backup resource $namespace/$backup_name for Cluster $cluster_name."

  # Manifeste minimal pour créer la ressource Backup CNPG
  cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: "${backup_name}"
  namespace: "${namespace}"
  labels:
    ${SNAPSHOT_MANGED_LABEL}: "true"
    ${SNAPSHOT_PVC_LABEL}: "${cluster_name}"
spec:
  method: volumeSnapshot
  cluster:
    name: ${cluster_name}
EOF
}

# Wait for a CNPG backup to be ready.
# Usage: wait_for_cnpg_backup "namespace" "name"
wait_for_cnpg_backup() {
  local namespace=$1
  local name=$2
  log "CNPG: Waiting for Backup $namespace/$name to complete..."

  if ! kubectl wait --for=jsonpath='{.status.phase}=completed' backup/"$name" -n "$namespace" --timeout=300s > /dev/null; then
    log "ERROR: CNPG Backup $namespace/$name failed or timed out."
    return 1
  fi
  return 0
}

# Find snapshot by PVC and partial name
# Usage: find_snapshot "namespace" "pvc_name" "name_prefix"
find_snapshot() {
  local namespace=$1
  local pvc_name=$2
  local prefix=$3

  kubectl get volumesnapshots -n "$namespace" -o json | \
    jq -rc --arg PVC "$pvc_name" --arg PREFIX "$prefix" '.items |
      map(select((.spec.source.persistentVolumeClaimName == $PVC) and (.metadata.name | contains($PREFIX)))) |
      sort_by(.metadata.creationTimestamp) |
      last'
}

# Checks if the snapshot reference (yesterday) exists on S3.
# Usage: check_s3_reference "namespace" "pvc_name" "snapshot_name_ref"
check_s3_reference() {
  local namespace=$1
  local pvc_name=$2
  local snap_ref=$3
  local s3_path="${S3_BUCKET_NAME}/${namespace}/${pvc_name}/${snap_ref}"

  # Check if file exist in s3 (filename is partial to ignore type, eg. namespace/pvc_name/date instead of namespace/pvc_name/date-full.zvol)
  if mc ls -r "${s3_path}" --json 2>/dev/null | jq -e '.[]' > /dev/null; then
    return 0
  else
    return 1
  fi
}

# Retry upload vers S3
# Usage: upload_with_retry "src_file" "s3_dest"
upload_with_retry() {
  local src=$1
  local dest=$2
  local attempt=0

  while [ "$attempt" -lt "$UPLOAD_RETRIES" ]; do
    attempt=$((attempt + 1))
    if mc cp --quiet "$src" "$dest" >/dev/null; then
      return 0
    elif [ "$attempt" -lt "$UPLOAD_RETRIES" ]; then
      log "WARNING: Attempt $attempt failed. Retrying in ${UPLOAD_RETRY_DELAY}s..."
      sleep "$UPLOAD_RETRY_DELAY"
    fi
  done
  return 1
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
  local s3_filename_suffix=""
  local backup_message=""
  local zfs_cmd=(zfs send -c)

  if [ "$FORCE_FULL_BACKUP" == "true" ] || [ "$FORCE_FULL_BACKUP" == "TRUE" ]; then
    s3_filename_suffix="-full"
    backup_message="full backup (FORCED by argument)"
  elif [ "$(date -d "$TODAY_YMD" +%u)" -eq "$FULL_BACKUP_DAY" ]; then
    s3_filename_suffix="-full"
    backup_message="full backup (Today is Full Backup Day)"
  else
    local yesterday_date_prefix
    yesterday_date_prefix=$(date -d "$TODAY_YMD yesterday" +%Y%m%d)
    local yesterday_ref
    if [ "$namespace" == "database" ]; then
      # Special use case for database
      yesterday_ref=$(find_snapshot "$namespace" "$pvc_name" "${CNPG_CLUSTER_NAME}-${yesterday_date_prefix}" || echo "")
    else
      yesterday_ref=$(find_snapshot "$namespace" "$pvc_name" "${pvc_name}-${yesterday_date_prefix}" || echo "")
    fi

    if [ "$yesterday_ref" != "null" ] && [ -n "$yesterday_ref" ]; then
      local yesterday_ref_name
      yesterday_ref_name=$(echo "$yesterday_ref" | jq -r ".metadata.name")
      if check_s3_reference "$namespace" "$pvc_name" "$yesterday_ref_name"; then
        # Find the ZFS fullname on host
        content_name=$(echo "$yesterday_ref" | jq -r ".status.boundVolumeSnapshotContentName")
        zfs_handle=$(kubectl get volumesnapshotcontent "$content_name" -o jsonpath='{.status.snapshotHandle}' || echo "")
        local full_zfs_ref
        full_zfs_ref=$(zfs list -t snapshot -H -o name 2>/dev/null | grep "$zfs_handle")

        if [ -n "$full_zfs_ref" ]; then
          zfs_cmd+=(-i "$full_zfs_ref")
          s3_filename_suffix="-incr"
          backup_message="incremental backup from $yesterday_ref_name"
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
  zfs_cmd+=("$full_zfs_snap")

  # Extract and compress to tmp file
  log "Starting ${backup_message}, extracting and compressing snapshot..."
  local tmp_file
  local file_size
  tmp_file=$(mktemp)
  if ! "${zfs_cmd[@]}" > "$tmp_file"; then
    if [ "${s3_filename_suffix}" == "-incr" ]; then
      log "WARNING: Incremental failed. Falling back to full backup."

      s3_filename_suffix="-full"
      if ! zfs send -c "$full_zfs_snap" > "$tmp_file"; then
        log "WARNING: ZFS send failed. Local snapshot is preserved."
        rm -f "$tmp_file"
        return 1
      fi
    else
      log "WARNING: ZFS send failed. Local snapshot is preserved."
      rm -f "$tmp_file"
      return 1
    fi
  fi
  file_size=$(stat -c%s "$tmp_file" | numfmt --to=iec --suffix=B)

  # Transfert it to S3
  local s3_full_path="${namespace}/${pvc_name}/${snap_name}${s3_filename_suffix}.zvol"
  log "Transfer it to S3 ($s3_full_path) [$file_size]..."
  if upload_with_retry "$tmp_file" "${S3_BUCKET_NAME}/${s3_full_path}"; then
    log "Upload successful."
    rm -f "$tmp_file"
    return 0
  else
    log "WARNING: S3 upload failed. Local snapshot is preserved."
    rm -f "$tmp_file"
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
  cutoff_timestamp=$(date -d "$TODAY_YMD -${KEEP_DAYS} days" +%s)

  # Find candidates for deletion (older than KEEP_DAYS)
  local label_selector="${SNAPSHOT_MANGED_LABEL}=true,${SNAPSHOT_PVC_LABEL}=${pvc_name}"
  kubectl get vs -n "$namespace" -l "$label_selector" -o json | \
  jq -rc --arg CUTOFF "$cutoff_timestamp" '.items[] |
    # Select snapshots older than the cutoff time
    select((.metadata.creationTimestamp | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < ($CUTOFF | tonumber))' |
  while read -r item_json; do
    local cnpg_backup_name
    cnpg_backup_name=$(echo "$item_json" | jq -r '.metadata.labels["cnpg.io/backupName"] // empty')
    local snap_name
    snap_name=$(echo "$item_json" | jq -r '.metadata.name')

    if [ -n "$cnpg_backup_name" ]; then
      log "  - Deleting backup $cnpg_backup_name (linked to snapshot $snap_name)."
      kubectl delete backup "$cnpg_backup_name" -n "$namespace" || true
    else
      log "  - Deleting snapshot $snap_name."
    fi

    kubectl delete volumesnapshot "$snap_name" -n "$namespace" || true
  done
}

# --- Main Logic ---

log "--- Starting Backup ---"

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
  log "WARNING: Webhook URL is not configured. Notification will not be sended."
fi

if ! validate_date_format "$TODAY_YMD"; then
  log "FATAL: Reference date ($TODAY_YMD) is invalid (expected YYYYMMDD)."
  send_notification "CRITICAL_FAILURE" "Invalid date format (expected YYYYMMDD) used by the script. Date: $TODAY_YMD"
  exit 1
fi

CURRENT_DATETIME="${TODAY_YMD}$(date +%H%M%S)"
SNAPSHOT_HOUR_PREFIX="${TODAY_YMD}$(date +%H)"
FAILED_PVCs=""
TOTAL_PVC_COUNT=0
FAILED_PVC_COUNT=0

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
  SNAP_NAME=$(find_snapshot "$namespace" "$pvc" "$SNAPSHOT_HOUR_PREFIX" | jq -r ".metadata.name")
  if [ "$SNAP_NAME" != "null" ] && [ -n "$SNAP_NAME" ]; then
    log "Found existing snapshot for hour: $SNAP_NAME. Skipping creation."

    if ! wait_for_snapshot "$namespace" "$SNAP_NAME"; then
      FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
      FAILED_PVCs+="- **$namespace/$pvc**: Failed on waiting snapshot to be ready.\n"
      continue
    fi
  else
    if [ "$namespace" == "database" ]; then
      BACKUP_RESOURCE_NAME="${CNPG_CLUSTER_NAME}-${CURRENT_DATETIME}"

      if ! create_cnpg_backup "$namespace" "$CNPG_CLUSTER_NAME" "$BACKUP_RESOURCE_NAME"; then
        FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
        FAILED_PVCs+="- **$namespace/$CNPG_CLUSTER_NAME**: Failed on creating CNPG backup.\n"
        continue
      fi
      if ! wait_for_cnpg_backup "$namespace" "$BACKUP_RESOURCE_NAME"; then
        FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
        FAILED_PVCs+="- **$namespace/$CNPG_CLUSTER_NAME**: Failed on waiting CNPG backup to be ready.\n"
        continue
      fi

      SNAP_NAME=$(kubectl get backup "$BACKUP_RESOURCE_NAME" -n "$namespace" -o jsonpath='{.status.snapshotBackupStatus.elements[0].name}' || echo "")
      if [ -z "$SNAP_NAME" ]; then
        log "ERROR: CNPG Backup $BACKUP_RESOURCE_NAME completed but did not expose the VolumeSnapshot name."
        FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
        FAILED_PVCs+="- **$namespace/$CNPG_CLUSTER_NAME**: CNPG Backup failed to link the VolumeSnapshot.\n"
        continue
      fi
    else
      SNAP_NAME="${pvc}-${CURRENT_DATETIME}"

      if ! create_snapshot "$namespace" "$pvc" "$SNAP_NAME"; then
        FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
        FAILED_PVCs+="- **$namespace/$pvc**: Failed on creating snapshot.\n"
        continue
      fi
      if ! wait_for_snapshot "$namespace" "$SNAP_NAME"; then
        FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
        FAILED_PVCs+="- **$namespace/$pvc**: Failed on waiting snapshot to be ready.\n"
        continue
      fi
    fi
  fi

  if ! stream_to_s3 "$namespace" "$SNAP_NAME" "$pvc"; then
    FAILED_PVC_COUNT=$((FAILED_PVC_COUNT + 1))
    FAILED_PVCs+="- **$namespace/$pvc**: Failed to send.\n"
  fi
  prune_snapshots "$namespace" "$pvc"
done

log "--- Backup finished (Success: $((TOTAL_PVC_COUNT - FAILED_PVC_COUNT)), Failed: $FAILED_PVC_COUNT, Total: $TOTAL_PVC_COUNT) ---"

# Clear trap to prevent infinite loop
trap - ERR

if [ "$FAILED_PVC_COUNT" -eq 0 ]; then
  exit 0
else
  # Send failed backup to discord
  DETAILS="The job have encounter $FAILED_PVC_COUNT fail(s) on $TOTAL_PVC_COUNT PVCs.\n\nDetails:\n${FAILED_PVCs::-2}"
  send_notification "MANAGED_FAILURE" "$DETAILS"

  exit 1
fi
