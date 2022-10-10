resource "random_string" "vault_filename" {
  length  = 16
  special = false
}
locals {
  vault_filename  = "~/v-${random_string.vault_filename.result}"
  vault_namespace = yamldecode(file("${local.manifests_folder}/vault.yaml")).spec.destination.namespace
  vault_pod       = "-n ${local.vault_namespace} vault-0"
}

resource "kubectl_manifest" "vault" {
  depends_on = [module.zfs, kubectl_manifest.argocd_project]

  yaml_body = templatefile("${local.manifests_folder}/vault.yaml", {
    url = "vault-secrets.${local.base_domain}"
  })
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
    content = templatefile("./scripts/vault/init.sh", {
      argocd_policy = file("./values/vault/argocd-policy.hcl")
      reader_policy = file("./values/vault/reader-policy.hcl")
    })
    destination = "/tmp/init-vault.sh"
  }

  // Init vault
  provisioner "remote-exec" {
    inline = [
      // Wait vault pod is running
      "until [ \"$(kubectl get pod ${local.vault_pod} -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done",
      // Init and unseal vault
      "kubectl exec ${local.vault_pod} -- /bin/sh -c \"`cat /tmp/init-vault.sh`\" > ${local.vault_filename}"
    ]
  }
}

data "remote_file" "vault_credentials" {
  depends_on = [null_resource.vault_init]

  path = local.vault_filename
}
locals {
  vault_root_token  = sensitive(jsondecode(data.remote_file.vault_credentials.content).root_token)
  vault_unseal_keys = sensitive(jsondecode(data.remote_file.vault_credentials.content).unseal_keys_b64)
}

resource "kubernetes_secret" "vault_keys" {
  depends_on = [data.remote_file.vault_credentials]

  metadata {
    name      = "vault-keys"
    namespace = local.vault_namespace
  }

  data = {
    key1 = local.vault_unseal_keys.0
  }
}
resource "null_resource" "vault_restart" {
  depends_on = [kubernetes_secret.vault_keys]

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
      "kubectl delete pod ${local.vault_pod} > /dev/null",
      // Wait for vault is up
      "until [ \"$(kubectl get pod ${local.vault_pod} -o=jsonpath='{.status.phase}' 2>/dev/null)\" = \"Running\" ]; do sleep 1; done"
    ]
  }
}
