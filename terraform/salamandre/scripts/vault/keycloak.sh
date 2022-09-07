#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

vault login -no-print "${root_tooken}"

vault kv put -mount=argocd keycloak/database \
  dbHost=postgresql.loc \
  dbPort=5432 \
  dbName="${database.name}" \
  dbUser="${database.user}" \
  dbPassword="${database.password}"

vault kv put -mount=argocd keycloak/auth \
  adminUser="${admin.user}" \
  adminPassword="${admin.password}"
