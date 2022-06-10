module "argocd" {
  source = "../common-modules/argocd_app"

  kubeconfig    = var.kubeconfig
  name          = "argo-cd"
  namespace     = "argo-cd"
  chart         = "argo-cd"
  repository    = "https://argoproj.github.io/argo-helm"
  chart_version = var.chart_versions.argocd

  server  = local.core_apps.cluster
  project = local.core_apps.project
  sync_policy = {
    automated = {
      prune    = true
      selfHeal = true
    }
  }

  values = templatefile("${path.module}/values/argo-cd.yaml.tpl", {
    base_domain     = local.base_domain
    has_ssl         = var.environment == "production"
    tls_secret_name = local.tls_secret_name
    clusters        = local.clusters
    admin_account   = var.environment == "vm"
  })
}
