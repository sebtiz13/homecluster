# Generate secrets and passwords
resource "random_string" "oidc_vault_secret" {
  length  = 32
  special = false
}
resource "random_uuid" "oidc_argocd_secret" {
}
resource "random_password" "keycloak_db_password" {
  length = 16
}
resource "random_password" "keycloak_admin_password" {
  length = 16
}
locals {
  oidc_secrets = {
    vault  = sensitive(random_string.oidc_vault_secret.result)
    argocd = sensitive(random_uuid.oidc_argocd_secret.result)
  }
  keycloak_admin_password = random_password.keycloak_admin_password.result
}

# Create keycloak secrets


resource "null_resource" "vault_keycloak_secret" {
  depends_on = [kubectl_manifest.vault]

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
        password = random_password.keycloak_db_password.result
      }
      admin = {
        user     = "admin"
        password = local.keycloak_admin_password
      }
    })
    destination = "/tmp/vault-keycloak.sh"
  }

  // Init vault
  provisioner "remote-exec" {
    inline = [
      // Create database user
      "sudo -u postgres -H -- psql -c \"CREATE USER keycloak CREATEDB PASSWORD '${random_password.keycloak_db_password.result}'\" > /dev/null",
      // Wait vault pod is running
      "until [ \"$(kubectl get pod -n vault vault-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/vault-keycloak.sh`\" > /dev/null"
    ]
  }
}

# Deploy keycloak
resource "kubectl_manifest" "keycloak" {
  depends_on         = [null_resource.vault_keycloak_secret]
  override_namespace = local.argocd_namespace

  yaml_body = templatefile("${local.manifests_folder}/salamandre/keycloak.yaml", {
    url = "sso.${local.base_domain}"

    argocd_url    = "argocd.${local.base_domain}"
    argocd_secret = local.oidc_secrets.argocd

    vault_url    = "vault.${local.base_domain}"
    vault_secret = local.oidc_secrets.vault
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

      oidc_url           = "http://oidc.${local.base_domain}"
      oidc_client_id     = "vault"
      oidc_client_secret = local.oidc_secrets.vault

      # Policies
      oidc_operator_policy = file("./values/vault/operator-policy.hcl")
      oidc_admin_policy    = file("./values/vault/admin-policy.hcl")
    })
    destination = "/tmp/vault-oidc.sh"
  }

  // Init vault
  provisioner "remote-exec" {
    inline = [
      // Wait vault and keycloak pod is running
      "until [ \"$(kubectl get pod -n vault vault-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      "until [ \"$(kubectl get pod -n keycloak keycloak-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/vault-oidc.sh`\" > /dev/null"
    ]
  }
}
