resource "helm_release" "argocd_deploy" {
  create_namespace = true

  name       = "argo-cd"
  namespace  = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.chart_versions.argocd

  values = [templatefile("./values/argo-cd.yaml.tftpl", {
    password  = var.argocd_admin_password
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
        server = local.clusters.salamandre
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind = "*"
      }]
    }
  })
}

data "kubectl_file_documents" "argocd" {
  content = file("${local.manifests_folder}/salamandre/argo-cd.yaml")
}
resource "kubectl_manifest" "argocd_sync" {
  depends_on         = [kubectl_manifest.argocd_project]
  count              = length(data.kubectl_file_documents.argocd.documents)
  yaml_body          = element(data.kubectl_file_documents.argocd.documents, count.index)
  override_namespace = local.argocd_namespace
}
