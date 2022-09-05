resource "random_string" "vault_filename" {
  length  = 16
  special = false
}
locals {
  vault_filename = "~/v-${random_string.vault_filename.result}"
}

data "kubectl_file_documents" "vault" {
  content = file("${local.manifests_folder}/salamandre/vault.yaml")
}
resource "kubectl_manifest" "vault" {
  depends_on         = [module.zfs, helm_release.argocd_deploy]
  count              = length(data.kubectl_file_documents.vault.documents)
  yaml_body          = element(data.kubectl_file_documents.vault.documents, count.index)
  override_namespace = local.argocd_namespace
}

resource "null_resource" "vault_init" {
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
    content = templatefile("./utils/init-vault.sh", {
      argocd_policy   = file("./values/vault/argocd-policy.hcl")
      reader_policy = file("./values/vault/reader-policy.hcl")
    })
    destination = "/tmp/init-vault.sh"
  }

  // Init vault
  provisioner "remote-exec" {
    inline = [
      // Wait vault pod is running
      "until [ \"$(kubectl get pod -n vault vault-0 -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec -n vault vault-0 -- /bin/sh -c \"`cat /tmp/init-vault.sh`\" > ${local.vault_filename}"
    ]
  }
}

data "remote_file" "vault_keys" {
  depends_on = [null_resource.vault_init]

  path = local.vault_filename
}
resource "local_sensitive_file" "vault_keys" {
  content  = data.remote_file.vault_keys.content
  filename = "${local.out_dir}/vault-keys.${var.environment}.json"
}

resource "kubectl_manifest" "vault_keys" {
  depends_on = [data.remote_file.vault_keys]

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "vault-keys"
      namespace = "vault"
    }
    type = "Opaque"
    data = {
      key1 = base64encode(jsondecode(data.remote_file.vault_keys.content).unseal_keys_b64.0)
    }
  })
  force_new = true
}

resource "null_resource" "vault_restart" {
  depends_on = [kubectl_manifest.vault_keys]

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.use_private_key ? file(local.ssh_connection.private_key) : null
    agent       = local.ssh_connection.agent
  }

  provisioner "remote-exec" {
    inline = [
      // Restart vault
      "kubectl delete pod -n vault vault-0 > /dev/null"
    ]
  }
}
