locals {
  argocd_app = {
    name       = "argo-cd"
    namespace  = "argo-cd"
    chart      = "argo-cd"
    repository = "https://argoproj.github.io/argo-helm"
    version    = var.chart_versions.argocd

    values = templatefile("./values/argo-cd.yaml.tftpl", {
      password = var.argocd_admin_password
    })
  }
}


resource "helm_release" "argocd_deploy" {
  create_namespace = true

  name       = local.argocd_app.name
  namespace  = local.argocd_app.namespace
  chart      = local.argocd_app.chart
  repository = local.argocd_app.repository
  version    = local.argocd_app.version

  values = [local.argocd_app.values]
}
locals {
  argocd_namespace = helm_release.argocd_deploy.namespace
}

resource "argocd_project" "core_apps" {
  metadata {
    name      = local.core_apps.project
    namespace = local.argocd_namespace
  }

  spec {
    description  = "core apps of cluster"
    source_repos = ["*"]

    destination {
      server    = local.core_apps.cluster
      namespace = "*"
    }
    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_application" "argo-cd" {
  metadata {
    name      = local.argocd_app.name
    namespace = local.argocd_namespace
  }

  spec {
    project = local.core_apps.project
    destination {
      server    = local.core_apps.cluster
      namespace = local.argocd_app.namespace
    }

    source {
      repo_url        = local.argocd_app.repository
      chart           = local.argocd_app.chart
      target_revision = local.argocd_app.version

      helm {
        values = local.argocd_app.values
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
