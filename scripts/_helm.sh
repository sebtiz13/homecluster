#!/bin/bash
APP_PATH=$1

# Split path in array (use set for sh)
IFS=/ read -r -a parts <<< "${APP_PATH//apps\//}"
export CLUSTER_NAME="${parts[0]}"
export PROJECT_NAME="${parts[1]}"
export APP_NAME="${parts[2]}"
export RELEASE_NAME="$CLUSTER_NAME-$APP_NAME"
unset parts

run_helm () {
  ENVIRONMENT=${ENVIRONMENT:-production}
  DOMAIN_NAME=${DOMAIN_NAME:-local.vm}

  # helm base arguments
  local helm_args="$RELEASE_NAME"
  if [ "$1" = "lint" ]; then
    helm_args=""
  fi

  # Overwrite config for environment
  if [ -f "$APP_PATH/appValues.$ENVIRONMENT.yaml" ]; then
    helm_args="$helm_args --set-file appValuesEnv="$APP_PATH/appValues.$ENVIRONMENT.yaml""
  fi
  if [ -f "$APP_PATH/values.$ENVIRONMENT.yaml" ]; then
    helm_args="$helm_args --f "$APP_PATH/values.$ENVIRONMENT.yaml""
  fi

  helm "$1" -f "$APP_PATH/values.yaml" $helm_args charts/common-app \
    --set releaseName="$APP_NAME" \
    --set-file appValues="$APP_PATH/appValues.yaml" \
    --set environment="$ENVIRONMENT" \
    --set project="$PROJECT_NAME" \
    --set baseDomain="$DOMAIN_NAME" \
    --set oidc.realm="${OIDC_REALM:-"https://sso.$DOMAIN_NAME/realms/developer"}"
}
