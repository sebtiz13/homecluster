resource "helm_release" "argocd_deploy" {
  create_namespace = true

  name       = "argo-cd"
  namespace  = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.argocd_version

  values = [templatefile("./values/argocd.yaml.tftpl", {
    core_apps = local.core_apps
  })]
}
locals {
  argocd_namespace = helm_release.argocd_deploy.namespace
}

resource "kubectl_manifest" "argocd_project" {
  depends_on = [helm_release.argocd_deploy]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name      = "cluster-core-apps"
      namespace = local.argocd_namespace
    }

    spec = {
      description = "core apps of cluster"
      sourceRepos = ["*"]
      destinations = [{
        namespace = "*"
        server    = local.clusters.salamandre
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  })
}

resource "kubectl_manifest" "argocd_sync" {
  depends_on         = [kubectl_manifest.argocd_project]
  override_namespace = local.argocd_namespace

  yaml_body = templatefile("${local.manifests_folder}/argocd.yaml", {
    url = "argocd.${local.base_domain}"

    oidc_url    = "sso.${local.base_domain}"
    oidc_secret = local.oidc_secrets.argocd
  })
}

data "kubernetes_secret" "argocd_admin_password" {
  depends_on = [helm_release.argocd_deploy]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = local.argocd_namespace
  }
}
