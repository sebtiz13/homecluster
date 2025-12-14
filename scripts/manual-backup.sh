#!/bin/bash
set -eo pipefail

if [ ! -z "$1" ]; then
  CUSTOM_DATE="$1"
else
  CUSTOM_DATE=$(date +%Y%m%d)
fi

NAMESPACE="backup"
CRONJOB_NAME="zfs-s3-backup"
CONTAINER_INDEX=0
JOB_NAME="manual-backup-$CUSTOM_DATE"

# ---

# Check if date is valid with "YYYYMMDD" format.
# Usage: validate_date_format "date"
validate_date_format() {
  local date_str="$1"

  # Check if format is valid
  local regex='^([0-9]{4})([0-9]{2})([0-9]{2})$'
  if [[ ! "$date_str" =~ $regex ]]; then
    echo "ERROR: Date '$date_str' is not in the required YYYYMMDD format (Regex failed)."
    return 1
  fi

  # Check if values is valid
  local year="${BASH_REMATCH[1]}"
  local month="${BASH_REMATCH[2]}"
  local day="${BASH_REMATCH[3]}"
  local canonical_date="${year}-${month}-${day}"
  if ! date -d "$canonical_date" >/dev/null 2>&1; then
    echo "ERROR: Date '$date_str' is structurally correct but is not a valid calendar date (e.g., February 30th)."
    return 1
  fi

  return 0
}

# ---

if ! validate_date_format "$CUSTOM_DATE"; then
  exit 1
fi

export YQ_CINDEX=$CONTAINER_INDEX
export YQ_DATE="$CUSTOM_DATE"

kubectl delete job -n "$NAMESPACE" "$JOB_NAME" || true
# Create JOB from original cronjob
kubectl create job "$JOB_NAME" --from=cronjob/"$CRONJOB_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | \
# Add date to env
yq eval ".spec.template.spec.containers[env(YQ_CINDEX)].env |= (. // []) + [{\"name\": \"MANUAL_DATE\", \"value\": \"\" + env(YQ_DATE)}]" | \
# Deploy job
kubectl create -f -

unset YQ_CINDEX YQ_DATE
