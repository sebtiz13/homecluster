resource "kubectl_manifest" "traefik" {
  depends_on         = [kubectl_manifest.argocd_project]
  override_namespace = local.argocd_namespace

  yaml_body = file("${local.manifests_folder}/salamandre/traefik.yaml")
}
