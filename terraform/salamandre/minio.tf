# Generate secrets and passwords
resource "random_password" "minio_root_password" {
  length = 16
}
locals {
  minio_root_password = random_password.minio_root_password.result
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
      root_tooken = local.vault_keys.root_token

      root = {
        user     = "root"
        password = local.minio_root_password
      }
    })
    destination = "/tmp/vault-minio.sh"
  }

  provisioner "remote-exec" {
    inline = [
      // Create key in vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/vault-minio.sh`\" > /dev/null"
    ]
  }
}

# Deploy minio
resource "kubectl_manifest" "minio" {
  depends_on         = [null_resource.vault_minio_secret]
  override_namespace = local.argocd_namespace

  yaml_body = templatefile("${local.manifests_folder}/minio.yaml", {
    url = "s3.${local.base_domain}"
  })
}
