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
  kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443 >/dev/null

%{ for name, data in kubernetes_roles ~}
vault write auth/kubernetes/role/${name} \
  %{ for sa in data.bound_service_accounts ~}
  bound_service_account_names=${sa.name} \
  bound_service_account_namespaces=${sa.namespace} \
  %{ endfor ~}
  %{ for policy in data.policies ~}
  policies=${policy} \
  %{ endfor ~}
  ttl=${data.ttl} >/dev/null
%{ endfor ~}

# Enable static secrets engine
vault secrets enable -path=salamandre kv-v2 >/dev/null
vault secrets enable -path=baku kv-v2 >/dev/null

# Create oidc credentials (for keycloak)
vault kv put salamandre/vault/oidc \
  clientID="${oidc.client_id}" \
  clientSecret="${oidc.client_secret}" >/dev/null

# out the init text
cat $OUTPUT
