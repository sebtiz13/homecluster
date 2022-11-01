resource "kubectl_manifest" "kubed" {
  depends_on = [argocd_cluster.kubernetes]

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/kubed.yaml")
}

resource "vault_kv_secret_v2" "kubed" {
  mount = "argocd"
  name  = "kubed/config"
  data_json = jsonencode({
    kubeconfig = local.kubeconfig
  })
}
