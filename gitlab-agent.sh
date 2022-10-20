#!/bin/sh
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./gitlab-agent.sh [salamandre.vm/sebtiz13.fr] <token>"
  exit 1
fi

if [ "$1" != "salamandre.vm" ] && [ "$1" != "sebtiz13.fr" ]; then
  echo "Incorrect domain. Valid value : 'salamandre.vm' or 'sebtiz13.fr'"
  exit 1
fi

ROOT_TOKEN=$(jq .vault.root_token ./out/credentials.json)
MANIFESTS_PATH="./apps/manifests/salamandre"
if [ "$1" = "salamandre.vm" ]; then
  MANIFESTS_PATH="./out/manifests/salamandre"
fi

# Generate KV keys
KV_KEYS="token=\"$2\""
if [ "$1" = "salamandre.vm" ]; then
  KV_KEYS="$KV_KEYS caCert=\"$(cat ./vagrant/.vagrant/ca/rootCA.pem)\""
fi

# Create kv values
kubectl exec --kubeconfig "./out/kubeconfig/${1}.yaml" -n vault vault-0 -- /bin/sh -c "
export VAULT_ADDR=http://127.0.0.1:8200; \
vault login -no-print \"${ROOT_TOKEN}\"; \
vault kv get -mount=argocd gitlab/agent > /dev/null 2>&1 ||\
  vault kv put -mount=argocd gitlab/agent $KV_KEYS"

# Deploy agent
kubectl apply --kubeconfig "./out/kubeconfig/${1}.yaml" -f $MANIFESTS_PATH/gitlab-agent.yaml
