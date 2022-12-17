#!/bin/sh
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

  # Run script (with skip dev project if prod)
  if [ "$ENVIRONMENT" = "dev" ] || [ "$APP_PATH" != "/dev/" ]; then
    $SCRIPT "$APP_PATH"
  fi
done
