locals {
  argocd_raw_manifest = templatefile("${local.manifests_folder}/argocd.yaml", {
    url             = "argocd.${local.base_domain}"
    tls_secret_name = local.tls_secret_name

    oidc_url    = "sso.${local.base_domain}"
    oidc_secret = local.oidc_secrets.argocd
  })
  argocd_manifest = yamldecode(local.argocd_raw_manifest)
}
resource "helm_release" "argocd_deploy" {
  depends_on = [kubernetes_namespace.labeled_namespace]
  timeout    = 10 * 60 // 10 min

  name       = local.argocd_manifest.metadata.name
  namespace  = local.argocd_manifest.metadata.namespace
  chart      = local.argocd_manifest.spec.source.chart
  repository = local.argocd_manifest.spec.source.repoURL
  version    = local.argocd_manifest.spec.source.targetRevision

  values = [local.argocd_manifest.spec.source.helm.values]
}

resource "kubectl_manifest" "argocd_project" {
  depends_on = [helm_release.argocd_deploy]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name      = "cluster-core-apps"
      namespace = helm_release.argocd_deploy.namespace
    }

    spec = {
      description = "core apps of cluster"
      sourceRepos = ["*"]
      destinations = [{
        namespace = "*"
        server    = local.clusters.salamandre
        }, {
        namespace = "*"
        server    = local.clusters.baku
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  })
}

resource "kubectl_manifest" "argocd_sync" {
  depends_on = [kubectl_manifest.argocd_project]

  yaml_body = local.argocd_raw_manifest
}

// Retrieve admin password
data "kubernetes_secret" "argocd_admin_password" {
  depends_on = [helm_release.argocd_deploy]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = helm_release.argocd_deploy.namespace
  }
}
