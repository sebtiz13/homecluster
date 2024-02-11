#!/bin/sh
if ! command -v kubectl  &> /dev/null; then
  echo "You should install kubectl to generate credentials"
  exit 1
fi
if ! command -v jq  &> /dev/null; then
  echo "You should install jq to generate credentials"
  exit 1
fi

ENVIRONMENT=${ENVIRONMENT:-prod}
if [ -z "$1" ]; then
  echo "Usage: ./gitlab-agent.sh <token>"
  exit 1
fi
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'prod'"
  exit 1
fi

# Define variables
KUBECONFIG="./out/kubeconfig/salamandre.${ENVIRONMENT}.yaml"
ROOT_TOKEN=$(jq .root_token "./out/credentials/salamandre/$ENVIRONMENT/vault.json")
MANIFESTS_PATH="./manifests/salamandre"
MANIFEST_FILE="gitlab-agent-homecluster.yaml"
KV_BASE_PATH="salamandre/gitlab/agents"
KV_PATH="$KV_BASE_PATH/homecluster"

if [ "$ENVIRONMENT" = "dev" ]; then
  MANIFESTS_PATH="./vagrant/.vagrant/manifests/salamandre"
fi

# Generate KV keys
KV_KEYS="token=\"$1\""
if [ "$ENVIRONMENT" = "dev" ]; then
  KV_KEYS="$KV_KEYS caCert=\"$(cat ./vagrant/.vagrant/ca/rootCA.pem)\""
fi

# Create kv values
kubectl exec -n vault vault-0 -- /bin/sh -c "
export VAULT_ADDR=http://127.0.0.1:8200; \
vault login -no-print \"${ROOT_TOKEN}\"; \
vault kv get $KV_PATH > /dev/null 2>&1 ||\
  vault kv put $KV_PATH $KV_KEYS"

# Deploy agent(s)
kubectl apply -n argocd -f "$MANIFESTS_PATH/$MANIFEST_FILE"
