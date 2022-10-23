resource "local_sensitive_file" "credentials" {
  filename = "${local.out_dir}/credentials.json"
  content = jsonencode({
    vault = {
      root_token  = local.vault_root_token
      unseal_keys = local.vault_unseal_keys
    }
    argocd_admin_password   = data.kubernetes_secret.argocd_admin_password.data.password
    keycloak_admin_password = local.keycloak_admin_password
    minio_admin_password    = local.minio_admin_password
  })
}
