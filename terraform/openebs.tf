resource "argocd_application" "openebs" {
  metadata {
    name      = "openebs"
    namespace = local.argocd_namespace
  }

  spec {
    project = local.core_apps.project
    destination {
      server    = local.core_apps.cluster
      namespace = "openebs"
    }

    source {
      repo_url        = "https://openebs.github.io/zfs-localpv"
      chart           = "zfs-localpv"
      target_revision = var.chart_versions.openebs

      helm {
        values = yamlencode({
          fullnameOverride = "openebs"
        })
      }
    }

    sync_policy {
      automated = {
        prune     = true
        self_heal = true
      }
    }
  }
}

resource "kubernetes_storage_class" "openebs_storageclass" {
  depends_on = [argocd_application.openebs]

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
