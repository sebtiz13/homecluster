locals {
  base_domain     = "sebtiz13.fr"
  tls_secret_name = replace(local.base_domain, ".", "-")

  clusters = {
    salamandre = "https://kubernetes.default.svc"
    baku       = "https://${var.environment == "vm" ? "baku.vm" : "baku." + local.base_domain}:6443"
  }
  core_apps = {
    project = "cluster-core-apps"
    cluster = local.clusters.salamandre
  }
}
