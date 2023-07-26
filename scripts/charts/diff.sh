#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-charts.sh <script>"
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

for FOLDER_PATH in $(git diff --dirstat=files,0 "$DIFF_RANGE" -- charts | sed 's/^[ 0-9.]\+% //g' | cut -d'/' -f 2 | sort -u)
do
  if [ -f "charts/$FOLDER_PATH/Chart.yaml" ]; then
    # Run script
    $SCRIPT "charts/$FOLDER_PATH"
  fi
done
