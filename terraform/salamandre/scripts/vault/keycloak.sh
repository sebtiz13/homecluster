#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

vault login -no-print "${root_tooken}"

vault kv put -mount=argocd keycloak/database \
  host=postgresql.loc \
  port=5432 \
  database="${database.name}" \
  user="${database.user}" \
  password="${database.password}"

vault kv put -mount=argocd keycloak/auth \
  adminUser="${admin.user}" \
  adminPassword="${admin.password}"
