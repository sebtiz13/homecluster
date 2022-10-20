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
module "minio_vault_secrets" {
  depends_on = [null_resource.vault_restart]
  source     = "./modules/vault"

  ssh = local.ssh_connection
  vault = {
    pod   = local.vault_pod
    token = local.vault_root_token
  }
  secrets = {
    "minio/auth" = {
      rootUser     = "admin"
      rootPassword = local.minio_admin_password
    }
  }
}

# Deploy app
resource "kubectl_manifest" "minio" {
  depends_on = [module.minio_vault_secrets, module.gitlab_vault_secrets, kubernetes_namespace.labeled_namespace]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.minio_manifest)
}
