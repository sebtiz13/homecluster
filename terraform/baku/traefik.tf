resource "kubectl_manifest" "traefik" {
  depends_on = [module.k3s_install]
  provider   = kubectl.salamandre

  yaml_body = file("${local.manifests_folder}/traefik.yaml")
}
