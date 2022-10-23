resource "kubectl_manifest" "traefik" {
  depends_on = [module.k3s_install]
  provider   = kubectl.salamandre

  override_namespace = "argocd"
  yaml_body          = file("${var.manifests_folder}/traefik.yaml")
}
