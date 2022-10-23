# Deploy app
resource "kubectl_manifest" "traefik" {
  depends_on = [helm_release.argocd_deploy]

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/traefik.yaml")
}
resource "null_resource" "traefik_wait" {
  depends_on = [kubectl_manifest.traefik]

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
      "until [ \"$(kubectl get deploy -n traefik traefik -o=jsonpath='{.status.readyReplicas}' 2>/dev/null)\" = \"1\" ]; do sleep 1; done"
    ]
  }
}
