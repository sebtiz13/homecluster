locals {
  name       = "argo-cd"
  namespace  = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.chart_versions.argocd

  values = templatefile("./values/argo-cd.yaml.tftpl", {
    base_domain     = local.base_domain
    has_ssl         = var.environment == "production"
    tls_secret_name = local.tls_secret_name
    core_apps       = local.core_apps
  })
}

provider "helm" {
  kubernetes {
    host = local.kubeconfig.host

    cluster_ca_certificate = base64decode(local.kubeconfig.cluster_ca_certificate)
    client_certificate     = base64decode(local.kubeconfig.client_certificate)
    client_key             = base64decode(local.kubeconfig.client_key)
  }
}

resource "helm_release" "argocd_deploy" {
  name       = local.name
  namespace  = local.namespace
  chart      = local.chart
  repository = local.repository
  version    = local.version

  values = [local.values]
}

module "argocd_sync" {
  source     = "./common-modules/argocd_app"
  depends_on_ = [helm_release.argocd_deploy]

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
