data "kubectl_file_documents" "traefik" {
  content = file("${local.manifests_folder}/salamandre/traefik.yaml")
}
resource "kubectl_manifest" "traefik" {
  depends_on         = [helm_release.argocd_deploy]
  count              = length(data.kubectl_file_documents.traefik.documents)
  yaml_body          = element(data.kubectl_file_documents.traefik.documents, count.index)
  override_namespace = local.argocd_namespace
}
