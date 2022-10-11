resource "kubectl_manifest" "external_secrets" {
  depends_on = [module.zfs, kubectl_manifest.argocd_project]
  yaml_body  = file("${local.manifests_folder}/external-secrets.yaml")
}
resource "null_resource" "external_secrets_wait" {
  depends_on = [kubectl_manifest.external_secrets]

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
      // Wait for external secrets is start
      "until [ \"$(kubectl get deploy -n ${local.vault_namespace} external-secrets-webhook -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}

locals {
  secretStoreRef = {
    name = "vault-argocd"
    kind = "ClusterSecretStore"
  }
}
resource "kubectl_manifest" "external_secrets_cluster_store" {
  depends_on = [null_resource.external_secrets_wait]

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = local.secretStoreRef.kind

    metadata = {
      name      = local.secretStoreRef.name
      namespace = local.vault_namespace
    }

    spec = {
      provider = {
        vault = {
          server = "http://vault-internal.vault.svc:8200"
          path   = "argocd"
          auth = {
            kubernetes = {
              mountPath = "kubernetes"
              role      = "argocd"
              serviceAccountRef = {
                name      = "argocd-repo-server"
                namespace = helm_release.argocd_deploy.namespace
              }
            }
          }
        }
      }
    }
  })
}
