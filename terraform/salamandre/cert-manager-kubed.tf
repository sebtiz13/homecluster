
locals {
  cm_manifest  = yamldecode(file("${var.manifests_folder}/cert-manager.yaml"))
  cm_namespace = local.cm_manifest.spec.destination.namespace
}

# Deploy apps
resource "kubectl_manifest" "cert_manager" {
  depends_on = [kubectl_manifest.argocd_projects]

  override_namespace = local.argocd_namespace
  yaml_body          = yamlencode(local.cm_manifest)
}

resource "kubectl_manifest" "kubed" {
  depends_on = [kubectl_manifest.argocd_projects]

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/kubed.yaml")
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
      "until [ \"$(kubectl get deploy -n ${local.cm_namespace} cert-manager-webhook -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}
