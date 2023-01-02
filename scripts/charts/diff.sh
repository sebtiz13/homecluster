#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-charts.sh <script>"
  exit 1
fi

matches() {
  echo "$1" | grep -q "$2"
}

for FOLDER_PATH in $(git diff --dirstat=files,0 HEAD~1 -- charts | sed 's/^[ 0-9.]\+% //g' | cut -d'/' -f 2 | sort -u)
do
  if [ -f "charts/$FOLDER_PATH/Chart.yaml" ]; then
    # Run script
    $SCRIPT "charts/$FOLDER_PATH"
  fi
done
