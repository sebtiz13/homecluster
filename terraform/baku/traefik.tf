resource "kubectl_manifest" "traefik" {
  depends_on = [module.k3s_install]
  provider   = kubectl.salamandre

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/traefik.yaml")
}
