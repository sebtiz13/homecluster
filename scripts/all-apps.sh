#!/bin/bash
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-app.sh <script>"
  exit 1
fi

for APP_PATH in apps/*/*/*/
do
  if [ "$APP_PATH" = "apps/*/*/*/" ]; then
    echo "No applications found"
    exit 0
  fi

  # Run script
  $SCRIPT "$APP_PATH"
done
