#!/bin/sh

OUTPUT=/tmp/keys.json
export VAULT_ADDR=http://127.0.0.1:8200

vault operator init -key-shares=1 -key-threshold=1 -format=json > $OUTPUT

unseal=$(sed "3q;d" $OUTPUT | sed 's/"//g' | tr -d '[:space:]') # This get char between 3rd `"` and 4th
root=$(cat $OUTPUT | grep -o '"root_token": "[^"]*' | grep -o '[^"]*$')

vault operator unseal $unseal >/dev/null
vault login -no-print $root >/dev/null

# Deploy policies
cat << EOF | vault policy write reader - >/dev/null
${reader_policy}
EOF
cat << EOF | vault policy write argocd - >/dev/null
${argocd_policy}
EOF

# Setup Kube Auth Method
vault auth enable kubernetes >/dev/null

vault write auth/kubernetes/config \
  disable_iss_validation="true" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443 \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt >/dev/null

vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=argocd \
  ttl=1h >/dev/null

# Enable static secrets
vault secrets enable -path=argocd kv-v2 >/dev/null

# out the init text
cat $OUTPUT
