#!/bin/sh
if [ -z "$1" ]; then
  echo "Usage: lint.sh apps/cluster/project/app"
  exit 1
fi

. "$(dirname "$0")/_helm.sh"
extract_info "$1"

# Run lint
echo "Lint: $RELEASE_NAME"
run_helm lint "$1"
