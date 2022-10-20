#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200
vault login -no-print ${token} >/dev/null

# Setup OIDC Auth Method
vault auth enable oidc

vault write auth/oidc/config \
  oidc_discovery_url="${oidc.url}" \
  oidc_client_id="${oidc.client_id}" \
  oidc_client_secret="${oidc.client_secret}" \
  default_role="reader"

vault write auth/oidc/role/reader bound_audiences="vault" \
  allowed_redirect_uris="${address}/ui/vault/auth/oidc/oidc/callback" \
  allowed_redirect_uris="http://localhost:8200/oidc/callback,http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
  user_claim="preferred_username" \
  groups_claim="groups" \
  policies="default,reader"

# Create policies and groups
mount_accessor=$(vault auth list | awk '$1=="oidc/" {print $3}')

## operator group
cat << EOF | vault policy write operator - >/dev/null
${policies.operator}
EOF

vault write identity/group name='Operator' policies='operator' type='external'
vault write identity/group-alias \
  name='Operator' \
  mount_accessor="$mount_accessor" \
  canonical_id="$(vault read identity/group/name/Operator | awk '$1=="id" {print $2}')"

## admin group
cat << EOF | vault policy write admin - >/dev/null
${policies.admin}
EOF

vault write identity/group name='Admin' policies='operator,admin' type='external'
vault write identity/group-alias \
  name='Admin' \
  mount_accessor="$mount_accessor" \
  canonical_id="$(vault read identity/group/name/Admin | awk '$1=="id" {print $2}')"
