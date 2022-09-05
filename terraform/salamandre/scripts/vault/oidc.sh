#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

vault login -no-print ${root_tooken} >/dev/null

# Setup OIDC Auth Method
vault auth enable oidc

vault write auth/oidc/config \
  oidc_discovery_url="${oidc_url}" \
  oidc_client_id="${oidc_client_id}" \
  oidc_client_secret="${oidc_client_secret}" \
  default_role="reader"

vault write auth/oidc/role/reader bound_audiences="vault" \
  allowed_redirect_uris="${address}/ui/vault/auth/oidc/oidc/callback"
  allowed_redirect_uris="http://localhost:8200/oidc/callback,http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
  user_claim="preferred_username" \
  groups_claim="groups" \
  policies="default,reader"

## operator group
cat << EOF | vault policy write operator - >/dev/null
${oidc_operator_policy}
EOF

vault write identity/group name='Operator' policies='operator' type='external'
vault write identity/group-alias \
  name='Operator' \
  mount_accessor="$(vault auth list -format=json | jq -r '.["oidc/"].accessor')" \
  canonical_id="$(vault read identity/group/name/Operator -format=json | jq -r ".data.id")"

## admin group
cat << EOF | vault policy write admin - >/dev/null
${oidc_admin_policy}
EOF

vault write identity/group name='Admin' policies='operator,admin' type='external'
vault write identity/group-alias \
  name='Admin' \
  mount_accessor="$(vault auth list -format=json | jq -r '.["oidc/"].accessor')" \
  canonical_id="$(vault read identity/group/name/Admin -format=json | jq -r ".data.id")"

# Enable static secrets
vault secrets enable -path=argocd kv-v2 >/dev/null

# out the init text
cat $OUTPUT
