#!/bin/sh
# helm dependency build --skip-refresh "$1" #? its run on lint
helm cm-push --username "$CI_REGISTRY_USER" --password "$CI_REGISTRY_PASSWORD" \
  "$1" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/${HELM_CHANNEL}"
