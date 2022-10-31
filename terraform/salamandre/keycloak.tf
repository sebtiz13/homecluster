# Extract values
locals {
  keycloak_disabled = contains(local.excluded_apps, "keycloak")
  keycloak_manifest = yamldecode(file("${var.manifests_folder}/keycloak.yaml"))
  keycloak_values   = yamldecode(local.keycloak_manifest.spec.source.plugin.env.1.value)

  keycloak_namespace = local.keycloak_manifest.spec.destination.namespace
  keycloak_host      = local.keycloak_values.ingress.hostname
  oidc_url           = "https://${local.keycloak_host}/realms/developer"
}

# Generate  password
resource "random_password" "keycloak_admin_password" {
  count   = local.keycloak_disabled ? 0 : 1
  length  = 16
  special = false
}
locals {
  keycloak_admin_password = try(random_password.keycloak_admin_password[0].result, null)
}

# Create database access
module "keycloak_database" {
  depends_on = [null_resource.postgresql_install]
  source     = "./modules/database"
  count      = local.keycloak_disabled ? 0 : 1

  ssh      = local.ssh_connection
  username = "keycloak"
  database = "keycloak"
}

# Create vault keys
module "keycloak_vault_secrets" {
  depends_on = [null_resource.vault_restart, module.keycloak_database]
  source     = "./modules/vault"
  count      = local.keycloak_disabled ? 0 : 1

  ssh = local.ssh_connection
  vault = {
    pod   = local.vault_pod
    token = local.vault_root_token
  }
  secrets = {
    "keycloak/database" = {
      host     = "postgresql.loc"
      port     = 5432
      database = "keycloak"
      user     = "keycloak"
      password = module.keycloak_database[0].password
    }
    "keycloak/auth" = {
      adminUser     = "admin"
      adminPassword = local.keycloak_admin_password
    }
  }
}

# Deploy keycloak
resource "kubectl_manifest" "keycloak" {
  depends_on = [module.keycloak_vault_secrets, module.argocd_vault_secrets]
  count      = local.keycloak_disabled ? 0 : 1

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.keycloak_manifest)
}
