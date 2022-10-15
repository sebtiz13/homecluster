resource "kubernetes_secret" "vm_ca" {
  depends_on = [module.k3s_install]
  count      = var.environment == "vm" ? 1 : 0

  metadata {
    name      = "vm-ca-tls-secret"
    namespace = "kube-system"
    annotations = {
      "kubed.appscode.com/sync" = "domain=${local.base_domain}"
    }
  }

  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = file(var.ca_cert)
    "tls.key" = file(var.ca_key)
  }
}

resource "null_resource" "argocd_restart" {
  depends_on = [kubectl_manifest.cert_manager, null_resource.vault_oidc]
  count      = var.environment == "vm" ? 1 : 0

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
      // Wait ca secret
      "until kubectl get secret -n argocd vm-ca-tls-secret &> /dev/null; do sleep 1; done",
      // Restart argocd
      "kubectl rollout restart deployment -n argocd argocd-server > /dev/null"
    ]
  }
}
