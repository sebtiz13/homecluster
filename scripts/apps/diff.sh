#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-app.sh <script>"
  exit 1
fi

matches() {
  echo "$1" | grep -q "$2"
}

# Retrieve commits want diff
DIFF_RANGE="HEAD~1"
if [ -n "$CI_MERGE_REQUEST_DIFF_BASE_SHA" ]; then
  DIFF_RANGE=$CI_MERGE_REQUEST_DIFF_BASE_SHA...HEAD
fi

for APP_PATH in $(git diff --dirstat=files,0 "$DIFF_RANGE" -- apps | sed 's/^[ 0-9.]\+% //g')
do
  # skip dev project if prod
  if [ "$ENVIRONMENT" = "dev" ] || ! matches "$APP_PATH" ".*/dev/*"; then
    # Check valid app and allow skip apps on prod
    if [ -f "${APP_PATH%?}/values.yaml" ] && ! matches "$APP_PATH" "${SKIP_APP:-'###'}"; then
      # Run script
      $SCRIPT "${APP_PATH%?}"
    fi
  fi
done
