#!/bin/sh
ENVIRONMENT=${ENVIRONMENT:-prod}
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./gitlab-agent.sh <local/homecluster> <token>"
  exit 1
fi
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "Incorrect environment. Valid value : 'dev' or 'prod'"
  exit 1
fi
if [ "$1" != "local" ] && [ "$1" != "homecluster" ]; then
  echo "Incorrect type. Valid value : 'local' or 'homecluster'"
  exit 1
fi

# Define variables
KUBECONFIG="./out/kubeconfig/salamandre.${ENVIRONMENT}.yaml"
ROOT_TOKEN=$(jq .root_token "./out/credentials/salamandre/$ENVIRONMENT/vault.json")
MANIFESTS_PATH="./manifests/salamandre"
MANIFEST_FILE="gitlab-agent.yaml"
KV_BASE_PATH="salamandre/gitlab/agents"
KV_PATH="$KV_BASE_PATH/local"

if [ "$ENVIRONMENT" = "dev" ]; then
  MANIFESTS_PATH="./vagrant/.vagrant/manifests/salamandre"
fi

# Specific values for homecluster agent
if [ "$1" = "homecluster" ]; then
  MANIFEST_FILE="gitlab-agent-homecluster.yaml"
  KV_PATH="$KV_BASE_PATH/homecluster"
fi

# Generate KV keys
KV_KEYS="token=\"$2\""
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
