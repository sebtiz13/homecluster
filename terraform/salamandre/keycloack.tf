# Generate secrets and passwords
resource "random_string" "oidc_vault_secret" {
  length  = 32
  special = false
}
resource "random_uuid" "oidc_argocd_secret" {
}
resource "random_password" "keycloack_db_password" {
  length = 16
}
resource "random_password" "keycloack_admin_password" {
  length = 16
}
locals {
  oidc_secrets = {
    vault  = sensitive(random_string.oidc_vault_secret.result)
    argocd = sensitive(random_uuid.oidc_argocd_secret.result)
  }
  keycloack_admin_password = random_password.keycloack_admin_password.result
}

# Create keycloack secrets


resource "null_resource" "vault_keycloack_secret" {
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
    content = templatefile("./scripts/vault/keycloack.sh", {
      root_tooken = local.vault_root_token

      database = {
        name     = "keycloack"
        user     = "keycloack"
        password = random_password.keycloack_db_password.result
      }
      admin = {
        user     = "admin"
        password = local.keycloack_admin_password
      }
    })
    destination = "/tmp/vault-keycloack.sh"
  }

  // Init vault
  provisioner "remote-exec" {
    inline = [
      // Create database user
      "sudo -u postgres -H -- psql -c \"CREATE USER keycloack CREATEDB PASSWORD '${random_password.keycloack_db_password.result}'\" > /dev/null",
      // Wait vault pod is running
      "until [ \"$(kubectl get pod -n vault vault-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/vault-keycloack.sh`\" > /dev/null"
    ]
  }
}

# Deploy keycloack
resource "kubectl_manifest" "keycloack" {
  depends_on         = [null_resource.vault_keycloack_secret]
  override_namespace = local.argocd_namespace

  yaml_body = templatefile("${local.manifests_folder}/salamandre/keycloack.yaml", {
    url = "sso.${local.base_domain}"

    argocd_url    = "argocd.${local.base_domain}"
    argocd_secret = local.oidc_secrets.argocd

    vault_url    = "vault.${local.base_domain}"
    vault_secret = local.oidc_secrets.vault
  })
}

# Configure oidc in vault
resource "null_resource" "vault_oidc" {
  depends_on = [kubectl_manifest.keycloack]

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
      // Wait vault and keycloack pod is running
      "until [ \"$(kubectl get pod -n vault vault-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      "until [ \"$(kubectl get pod -n keycloack keycloack-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/vault-oidc.sh`\" > /dev/null"
    ]
  }
}
