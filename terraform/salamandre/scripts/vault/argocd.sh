#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200
vault login -no-print "${root_tooken}"

vault kv put argocd/argocd/oidc \
  issuer="${oidc.url}" \
  cliClientID="${oidc.cli_client_id}" \
  clientID="${oidc.client_id}" \
  clientSecret="${oidc.client_secret}"
