resource "kubectl_manifest" "traefik" {
  depends_on         = [helm_release.argocd_deploy]
  override_namespace = local.argocd_namespace

  yaml_body = file("${local.manifests_folder}/salamandre/traefik.yaml")
}
