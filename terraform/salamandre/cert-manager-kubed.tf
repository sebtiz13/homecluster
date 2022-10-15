
# Deploy apps
resource "kubectl_manifest" "cert_manager" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = templatefile("${local.manifests_folder}/cert-manager.yaml", {
  })
}
resource "null_resource" "cert_manager_wait" {
  depends_on = [kubectl_manifest.cert_manager]

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
      "until [ \"$(kubectl get deploy -n cert-manager cert-manager-webhook -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}

resource "kubectl_manifest" "kubed" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = file("${local.manifests_folder}/kubed.yaml")
}

# Create issuer
# TODO: Support production !
resource "kubectl_manifest" "cert_manager_issuer" {
  depends_on = [kubernetes_secret.vm_ca, null_resource.cert_manager_wait]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name      = "selfsigned"
      namespace = "cert-manager"
    }

    spec = {
      ca = {
        secretName = kubernetes_secret.vm_ca[0].metadata[0].name
      }
    }
  })
}
