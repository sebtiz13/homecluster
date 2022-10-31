#!/bin/sh
# shellcheck disable=SC3054

extract_info () {
  CLUSTER_NAME=$(basename "$(dirname "$(dirname "$1")")")
  PROJECT_NAME=$(basename "$(dirname "$1")")
  APP_NAME=$(basename "$1")
  RELEASE_NAME="$CLUSTER_NAME-$APP_NAME"

  export CLUSTER_NAME PROJECT_NAME APP_NAME RELEASE_NAME
}

run_helm () {
  ENVIRONMENT=${ENVIRONMENT:-production}
  DOMAIN_NAME=${DOMAIN_NAME:-local.vm}

  # helm base arguments
  helm_args="$RELEASE_NAME"
  if [ "$1" = "lint" ]; then
    helm_args=""
  fi

  # Overwrite config for environment
  if [ -f "$2/appValues.$ENVIRONMENT.yaml" ]; then
    helm_args="$helm_args --set-file appValuesEnv="$2/appValues.$ENVIRONMENT.yaml""
  fi
  if [ -f "$2/values.$ENVIRONMENT.yaml" ]; then
    helm_args="$helm_args -f "$2/values.$ENVIRONMENT.yaml""
  fi

  helm "$1" --set destination.server="$CLUSTER_NAME" \
     -f "$2/values.yaml" $helm_args charts/common-app \
    --set releaseName="$APP_NAME" \
    --set-file appValues="$2/appValues.yaml" \
    --set environment="$ENVIRONMENT" \
    --set project="$PROJECT_NAME" \
    --set baseDomain="$DOMAIN_NAME" \
    --set oidc.realm="${OIDC_REALM:-"https://sso.$DOMAIN_NAME/realms/developer"}"
}
