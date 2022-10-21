#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: build.sh apps/cluster/project/app"
  exit 1
fi
MANIFESTS_PATH=${MANIFESTS_PATH:-"$(dirname "$0")/../manifests"}

source "$(dirname "$0")/_helm.sh" "$1"

# Run build
echo "Build: $RELEASE_NAME"
mkdir -p "$MANIFESTS_PATH/$CLUSTER_NAME"
run_helm template > "$MANIFESTS_PATH/$CLUSTER_NAME/$APP_NAME.yaml"
