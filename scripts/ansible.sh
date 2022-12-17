#!/bin/bash
ENVIRONMENT=${ENVIRONMENT:-prod}
DOMAIN_NAME=${DOMAIN_NAME:-local.vm}
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'prod'"
  exit 1
fi

cd ansible || return
if [ "$ENVIRONMENT" == "dev" ]; then
  export ANSIBLE_HOST_KEY_CHECKING=false
fi
ansible-playbook --inventory "inventories/$ENVIRONMENT" --extra-vars "root_domain='${DOMAIN_NAME}'" $1 site.yaml
