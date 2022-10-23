#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-charts.sh <script>"
  exit 1
fi

for FOLDER_PATH in $(git diff --dirstat=files,0 HEAD~1 -- charts | sed 's/^[ 0-9.]\+% //g')
do
  # Run script
  $SCRIPT "charts/$(echo "$FOLDER_PATH" | cut -d'/' -f 2)"
done
