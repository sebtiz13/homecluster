#!/bin/bash
set -eo pipefail

# --- Variables ---

NAMESPACE="backup"
CRONJOB_NAME="zfs-s3-backup"
CONTAINER_INDEX=0
JOB_NAME_PREFIX="manual-backup"

# --- Functions ---

# Show command usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Launch an save Kubernetes job based on existing CronJob."
  echo ""
  echo "OPTIONS:"
  echo "  -d, --date YYYYMMDD Force run an specific date backup (mainly for testing)."
  echo "                      (Default: Today)"
  echo "  -f, --full          Force an full backup (ignore incremental logic)."
  echo "  -h, --help          Show this help message."
  echo ""
}

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

# --- Main logic ---

FORCE_FULL_BACKUP=false

# Parse argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --date|-d)
      if [ -n "$2" ]; then
        CUSTOM_DATE="$2"
        shift 2 # Consume flag and value
      else
        echo "ERROR: --date require an value in YYYYMMDD format."
        usage
        exit 1
      fi
      ;;
    --full|-f)
      FORCE_FULL_BACKUP=true
      echo "INFO: Full backup mode requested."
      shift # Consume flag
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Invalid argument: $1"
      usage
      exit 1
      ;;
  esac
done

# Fallback date to today
if [ -z "$CUSTOM_DATE" ]; then
  CUSTOM_DATE=$(date +%Y%m%d)
fi

if ! validate_date_format "$CUSTOM_DATE"; then
  exit 1
fi

JOB_NAME="${JOB_NAME_PREFIX}-$CUSTOM_DATE"
export YQ_CINDEX=$CONTAINER_INDEX
export YQ_DATE="$CUSTOM_DATE"
export YQ_FULL_FLAG="$FORCE_FULL_BACKUP"

kubectl delete job -n "$NAMESPACE" "$JOB_NAME" || true
# Create JOB from original cronjob
kubectl create job "$JOB_NAME" --from=cronjob/"$CRONJOB_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | \
# Add env variables
yq eval '.spec.template.spec.containers[env(YQ_CINDEX)].env |= (. // []) +
  [{"name": "MANUAL_DATE", "value": "" + env(YQ_DATE)}] +
  [{"name": "FORCE_FULL_BACKUP", "value": "" + env(YQ_FULL_FLAG)}]' | \
# Deploy job
kubectl create -f -

unset YQ_CINDEX YQ_DATE YQ_FULL_FLAG

echo "SUCCESS: Job $JOB_NAME as been created. Use 'kubectl logs -f job/$JOB_NAME -n $NAMESPACE' to see logs."
