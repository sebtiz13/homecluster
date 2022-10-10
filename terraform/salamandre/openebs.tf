resource "kubectl_manifest" "openebs" {
  depends_on = [module.zfs, kubectl_manifest.argocd_project]
  yaml_body  = file("${local.manifests_folder}/openebs.yaml")
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
