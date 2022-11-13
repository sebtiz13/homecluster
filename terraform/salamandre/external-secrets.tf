locals {
  es_manifest  = yamldecode(file("${var.manifests_folder}/external-secrets.yaml"))
  es_namespace = local.es_manifest.spec.destination.namespace
}

# Deploy app
resource "kubectl_manifest" "external_secrets" {
  depends_on = [module.zfs, helm_release.argocd_deploy]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.es_manifest)
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
      "until [ \"$(kubectl get deploy -n ${local.es_namespace} external-secrets-webhook -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}

# Create store connection with vault
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
      namespace = local.es_namespace
    }

    spec = {
      provider = {
        vault = {
          server = "http://vault-internal.${local.vault_namespace}.svc:8200"
          auth = {
            kubernetes = {
              mountPath = "kubernetes"
              role      = "external-secrets"
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = local.es_namespace
              }
            }
          }
        }
      }
    }
  })
}
