# Generate passwords
resource "random_password" "minio_admin_password" {
  length  = 16
  special = false
}
locals {
  minio_url            = "s3.${local.base_domain}"
  minio_admin_password = random_password.minio_admin_password.result
  minio_endpoint       = "minio.minio.svc.cluster.local:9000"
  minio_region         = "minio"
}

# Create vault keys
resource "null_resource" "vault_minio_secret" {
  depends_on = [null_resource.vault_restart, kubernetes_storage_class.openebs_storageclass]

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.use_private_key ? file(local.ssh_connection.private_key) : null
    agent       = local.ssh_connection.agent
  }

  // Upload files
  provisioner "file" {
    content = templatefile("./scripts/vault/minio.sh", {
      root_tooken = local.vault_root_token

      root = {
        user     = "admin"
        password = local.minio_admin_password
      }
    })
    destination = "/tmp/vault-minio.sh"
  }

  provisioner "remote-exec" {
    inline = [
      // Create key in vault
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/vault-minio.sh`\" > /dev/null"
    ]
  }
}

# Deploy minio
resource "kubectl_manifest" "minio" {
  depends_on = [null_resource.vault_minio_secret, null_resource.vault_gitlab_secret]

  yaml_body = templatefile("${local.manifests_folder}/minio.yaml", {
    url = local.minio_url
  })
}
