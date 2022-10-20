# Generate passwords
resource "random_password" "minio_admin_password" {
  length  = 16
  special = false
}
locals {
  minio_manifest = yamldecode(file("${var.manifests_folder}/minio.yaml"))
  minio_values   = yamldecode(local.minio_manifest.spec.source.plugin.env.1.value)

  minio_namespace = local.minio_manifest.spec.destination.namespace
  minio_host      = local.minio_values.ingress.hosts.0

  minio_admin_password = random_password.minio_admin_password.result
  minio_endpoint       = "minio.${local.minio_namespace}.svc.cluster.local:9000"
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

# Deploy app
resource "kubectl_manifest" "minio" {
  depends_on = [
    null_resource.vault_minio_secret,
    null_resource.vault_gitlab_secret,
    kubernetes_namespace.labeled_namespace
  ]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.minio_manifest)
}
