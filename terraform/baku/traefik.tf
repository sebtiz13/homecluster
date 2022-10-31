resource "kubectl_manifest" "traefik" {
  depends_on = [argocd_cluster.kubernetes]
  provider   = kubectl.salamandre

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/traefik.yaml")
}
