resource "local_sensitive_file" "credentials" {
  filename = "${local.out_dir}/credentials/baku.${var.environment}.json"
  content = jsonencode({
    minio_admin_password = local.minio_admin_password
  })
}
