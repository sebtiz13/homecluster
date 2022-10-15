# Generate secrets and passwords
resource "random_string" "oidc_vault_secret" {
  length  = 32
  special = false
}
resource "random_uuid" "oidc_argocd_secret" {
}
resource "random_string" "oidc_gitlab_secret" {
  length  = 32
  special = false
}
resource "random_password" "keycloak_admin_password" {
  length  = 16
  special = false
}
locals {
  oidc_url = "https://sso.${local.base_domain}/realms/developer"
  oidc_secrets = {
    vault  = sensitive(random_string.oidc_vault_secret.result)
    argocd = sensitive(random_uuid.oidc_argocd_secret.result)
    gitlab = sensitive(random_string.oidc_gitlab_secret.result)
  }
  keycloak_admin_password = random_password.keycloak_admin_password.result
}

module "keycloak_database" {
  source     = "./modules/database"
  depends_on = [null_resource.postgresql_install]

  ssh      = local.ssh_connection
  username = "keycloak"
  database = "keycloak"
}

# Create vault keys
resource "null_resource" "vault_keycloak_secret" {
  depends_on = [null_resource.vault_restart, null_resource.postgresql_install]

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
    content = templatefile("./scripts/vault/keycloak.sh", {
      root_tooken = local.vault_root_token

      database = {
        name     = "keycloak"
        user     = "keycloak"
        password = module.keycloak_database.password
      }
      admin = {
        user     = "admin"
        password = local.keycloak_admin_password
      }
    })
    destination = "/tmp/vault-keycloak.sh"
  }

  // Apply file
  provisioner "remote-exec" {
    inline = [
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/vault-keycloak.sh`\" > /dev/null"
    ]
  }
}

# Deploy keycloak
resource "kubectl_manifest" "keycloak" {
  depends_on = [null_resource.vault_keycloak_secret]

  yaml_body = templatefile("${local.manifests_folder}/keycloak.yaml", {
    url             = "sso.${local.base_domain}"
    tls_secret_name = local.tls_secret_name

    argocd_url    = "argocd.${local.base_domain}"
    argocd_secret = local.oidc_secrets.argocd

    vault_url    = "vault-secrets.${local.base_domain}"
    vault_secret = local.oidc_secrets.vault

    gitlab_url    = "git.${local.base_domain}"
    gitlab_secret = local.oidc_secrets.gitlab
  })
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
      address     = "https://vault-secrets.${local.base_domain}"
      root_tooken = local.vault_root_token

      oidc_url           = local.oidc_url
      oidc_client_id     = "vault"
      oidc_client_secret = local.oidc_secrets.vault

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
