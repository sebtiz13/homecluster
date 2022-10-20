# Generate  password
resource "random_password" "keycloak_admin_password" {
  length  = 16
  special = false
}

# Extract values
locals {
  keycloak_admin_password = random_password.keycloak_admin_password.result
  keycloak_manifest       = yamldecode(file("${var.manifests_folder}/keycloak.yaml"))
  keycloak_values         = yamldecode(local.keycloak_manifest.spec.source.plugin.env.1.value)

  keycloak_namespace = local.keycloak_manifest.spec.destination.namespace
  keycloak_host      = local.keycloak_values.ingress.hostname
  oidc_url           = "https://${local.keycloak_host}/realms/developer"
}

# Create database access
module "keycloak_database" {
  source     = "./modules/database"
  depends_on = [null_resource.postgresql_install]

  ssh      = local.ssh_connection
  username = "keycloak"
  database = "keycloak"
}

# Create vault keys
module "keycloak_vault_secrets" {
  depends_on = [null_resource.vault_restart, module.keycloak_database]
  source     = "./modules/vault"

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
      password = module.keycloak_database.password
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

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.keycloak_manifest)
}

# Configure oidc in vault
resource "null_resource" "vault_oidc" {
  depends_on = [kubectl_manifest.keycloak]

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
    content = templatefile("./scripts/vault/oidc.sh", {
      address     = local.vault_host
      root_tooken = local.vault_root_token

      oidc_url           = local.oidc_url
      oidc_client_id     = "vault"
      oidc_client_secret = sensitive(random_string.oidc_vault_secret.result)

      # Policies
      oidc_operator_policy = file("./values/vault/operator-policy.hcl")
      oidc_admin_policy    = file("./values/vault/admin-policy.hcl")
    })
    destination = "/tmp/vault-oidc.sh"
  }

  provisioner "remote-exec" {
    inline = [
      // Wait keycloack is configurate
      "until [ \"$(curl -s '${local.oidc_url}' --max-time 2 | grep -o '\"realm\":\"[^\"]*' | grep -o '[^\"]*$' 2>/dev/null)\" = \"developer\" ]; do sleep 1; done",
      // Enable OIDC on vault
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/vault-oidc.sh`\" > /dev/null"
    ]
  }
}
