#!/bin/sh
export VAULT_ADDR=http://127.0.0.1:8200

vault login -no-print "${root_tooken}"

vault kv put -mount=argocd gitlab/database \
  host=postgresql.loc \
  database="${database.database}" \
  user="${database.user}" \
  password="${database.password}"

vault kv put -mount=argocd gitlab/s3 \
  endpoint="${s3.endpoint}" \
  region="${s3.region}" \
  accessKey="${s3.accessKey}" \
  secretKey="${s3.secretKey}" \
  bucket_artifacts="${s3.buckets.artifacts}" \
  bucket_backups="${s3.buckets.backups}" \
  bucket_depsProxy="${s3.buckets.depsProxy}" \
  bucket_packages="${s3.buckets.packages}" \
  bucket_runner="${s3.buckets.runner}" \
  bucket_tfState="${s3.buckets.tfState}" \
  bucket_uploads="${s3.buckets.uploads}" \
  bucket_lfs="${s3.buckets.lfs}"

vault kv put -mount=argocd gitlab/oidc \
  issuer="${oidc.url}" \
  clientId="${oidc.clientId}" \
  clientSecret="${oidc.clientSecret}"

vault kv put -mount=argocd gitlab/runner \
  registrationToken="${runner.registrationToken}"
