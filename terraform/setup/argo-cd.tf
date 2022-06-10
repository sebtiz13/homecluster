locals {
  name       = "argo-cd"
  namespace  = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.chart_versions.argocd

  values = templatefile("${path.module}/../apps/values/argo-cd.yaml.tpl", {
    base_domain     = local.base_domain
    has_ssl         = var.environment == "production"
    tls_secret_name = local.tls_secret_name
    clusters        = local.clusters
    admin_account   = var.environment == "vm"
  })
}

module "argocd_deploy" {
  source = "../common-modules/helm_release"

  kubeconfig    = local.kubeconfig
  name          = local.name
  namespace     = local.namespace
  chart         = local.chart
  repository    = local.repository
  chart_version = local.version
  values        = local.values
}

module "argocd_sync" {
  source      = "../common-modules/argocd_app"
  depends_on_ = [module.argocd_deploy]

  kubeconfig    = local.kubeconfig
  name          = local.name
  namespace     = local.namespace
  chart         = local.chart
  repository    = local.repository
  chart_version = local.version
  values        = local.values

  server  = local.core_apps.cluster
  project = local.core_apps.project
  sync_policy = {
    automated = {
      prune    = true
      selfHeal = true
    }
  }
}
