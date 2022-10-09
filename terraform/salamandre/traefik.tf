resource "kubectl_manifest" "traefik" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = file("${local.manifests_folder}/traefik.yaml")
}
