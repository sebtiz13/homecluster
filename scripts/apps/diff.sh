#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-app.sh <script>"
  exit 1
fi

for APP_PATH in $(git diff --dirstat=files,0 HEAD~1 -- apps | sed 's/^[ 0-9.]\+% //g')
do
  # Run script
  $SCRIPT "${APP_PATH%?}"
done
