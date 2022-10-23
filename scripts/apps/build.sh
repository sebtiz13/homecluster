#!/bin/sh
if [ -z "$1" ]; then
  echo "Usage: build.sh apps/cluster/project/app"
  exit 1
fi
MANIFESTS_PATH=${MANIFESTS_PATH:-"$(dirname "$0")/../../manifests"}

. "$(dirname "$0")/_helm.sh"
extract_info "$1"

# Run build
printf "\033[1;34mBuild\033[0m: %s\n" "$RELEASE_NAME"
mkdir -p "$MANIFESTS_PATH/$CLUSTER_NAME"
run_helm template "$1" > "$MANIFESTS_PATH/$CLUSTER_NAME/$APP_NAME.yaml"
