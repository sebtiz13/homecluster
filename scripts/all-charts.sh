#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-charts.sh <script>"
  exit 1
fi

for CHART_PATH in charts/*/
do
  # Run script (with skip charts/common-app)
  if [ "$CHART_PATH" != "charts/common-app" ]; then
    $SCRIPT "$CHART_PATH"
  fi
done
