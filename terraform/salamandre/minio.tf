# Extract values
locals {
  minio_disabled = contains(local.excluded_apps, "minio")
  minio_manifest = yamldecode(file("${var.manifests_folder}/minio.yaml"))
  minio_values   = yamldecode(local.minio_manifest.spec.source.plugin.env.1.value)

  minio_namespace = local.minio_manifest.spec.destination.namespace
  minio_host      = local.minio_values.ingress.hosts.0

  minio_endpoint = "minio.${local.minio_namespace}.svc.cluster.local:9000"
  minio_region   = "minio"
}

# Generate password
resource "random_password" "minio_admin_password" {
  count   = local.minio_disabled ? 0 : 1
  length  = 16
  special = false
}
locals {
  minio_admin_password = try(random_password.minio_admin_password[0].result, null)
}

# Create vault keys
module "minio_vault_secrets" {
  depends_on = [null_resource.vault_restart]
  source     = "./modules/vault"
  count      = local.minio_disabled ? 0 : 1

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
  count      = local.minio_disabled ? 0 : 1

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.minio_manifest)
}
