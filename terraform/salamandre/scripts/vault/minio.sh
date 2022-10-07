#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

vault login -no-print "${root_tooken}"

vault kv put -mount=argocd minio/auth \
  rootUser="${root.user}" \
  rootPassword="${root.password}"
