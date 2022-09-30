data "kubectl_file_documents" "openebs" {
  content = file("${local.manifests_folder}/openebs.yaml")
}
resource "kubectl_manifest" "openebs" {
  depends_on         = [module.zfs, kubectl_manifest.argocd_project]
  count              = length(data.kubectl_file_documents.openebs.documents)
  yaml_body          = element(data.kubectl_file_documents.openebs.documents, count.index)
  override_namespace = local.argocd_namespace
}

resource "kubernetes_storage_class" "openebs_storageclass" {
  depends_on = [kubectl_manifest.openebs]

  metadata {
    name = "openebs-zfspv"
  }
  storage_provisioner = "zfs.csi.openebs.io"

  parameters = {
    recordsize  = "4k"
    compression = "off"
    dedup       = "off"
    fstype      = "zfs"
    poolname    = "data"
  }
}
