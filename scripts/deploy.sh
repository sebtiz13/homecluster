#!/bin/bash
deploy_apps=""
if [ "$DEPLOY_SALAMANDRE_APPS" != "" ]; then
  deploy_apps="salamandre/${DEPLOY_SALAMANDRE_APPS//,/,salamandre/}"
fi
if [ "$DEPLOY_BAKU_APPS" != "" ]; then
  if [ "$deploy_apps" != "" ]; then
    deploy_apps="${deploy_apps},"
  fi

  deploy_apps="${deploy_apps}baku/${DEPLOY_BAKU_APPS//,/,baku/}"
fi

for MANIFEST in $(git diff --name-only HEAD~1 -- manifests)
do
  APP_PATH=$(echo "$MANIFEST" | sed 's#manifests/\(.*\).yaml#\1#')
  if [[ "$deploy_apps" == *"$APP_PATH"* ]]; then
    kubectl apply -n "$K8S_NAMESPACE" -f "$MANIFEST"
  fi
done
