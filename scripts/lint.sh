#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: lint.sh apps/cluster/project/app"
  exit 1
fi

source "$(dirname "$0")/_helm.sh" "$1"

# Run lint
echo "Lint: $RELEASE_NAME"
run_helm lint
