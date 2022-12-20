#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-app.sh <script>"
  exit 1
fi

matches() {
  echo "$1" | grep -q "$2"
}

for APP_PATH in $(git diff --dirstat=files,0 HEAD~1 -- apps | sed 's/^[ 0-9.]\+% //g')
do
  # Run script (with skip dev project if prod)
  if [ "$ENVIRONMENT" = "dev" ] || ! matches "$APP_PATH" "*/dev/*"; then
    if [ -f "${APP_PATH%?}/values.yaml" ]; then
      $SCRIPT "${APP_PATH%?}"
    fi
  fi
done
