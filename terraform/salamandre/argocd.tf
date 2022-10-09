locals {
  argocd_app_values = yamldecode(file("${local.manifests_folder}/argocd.yaml"))
}
resource "helm_release" "argocd_deploy" {
  create_namespace = true

  name       = local.argocd_app_values.metadata.name
  namespace  = local.argocd_app_values.metadata.namespace
  chart      = local.argocd_app_values.spec.source.chart
  repository = local.argocd_app_values.spec.source.repoURL
  version    = local.argocd_app_values.spec.source.targetRevision

  values = [file("./values/argocd.yaml.tftpl")]
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
    namespace = helm_release.argocd_deploy.namespace
  }
}
