resource "kubectl_manifest" "traefik" {
  depends_on         = [module.k3s_install]
  provider           = kubectl.salamandre
  override_namespace = var.argocd_namespace

  yaml_body = file("${local.manifests_folder}/traefik.yaml")
}
