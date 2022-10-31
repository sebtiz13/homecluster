resource "kubectl_manifest" "openebs" {
  depends_on = [argocd_cluster.kubernetes, module.zfs]
  provider   = kubectl.salamandre

  override_namespace = local.argocd_namespace
  yaml_body          = file("${var.manifests_folder}/openebs.yaml")
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
