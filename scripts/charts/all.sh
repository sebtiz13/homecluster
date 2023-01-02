#!/bin/sh
SCRIPT=$1
if [ -z "$SCRIPT" ]; then
  echo "Usage: diff-charts.sh <script>"
  exit 1
fi

matches() {
  echo "$1" | grep -q "$2"
}

for CHART_PATH in charts/*/
do
  if [ -f "$CHART_PATH/Chart.yaml" ]; then
    # Run script
    $SCRIPT "$CHART_PATH"
  fi
done
