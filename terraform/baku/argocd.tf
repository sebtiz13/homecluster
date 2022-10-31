locals {
  argocd_namespace = "argocd"
}

# Install RBAC resources for managing the cluster from salamandre
resource "kubernetes_service_account" "argocd_sa" {
  depends_on = [module.k3s_install]

  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
  automount_service_account_token = false
}

resource "kubernetes_cluster_role" "argocd_cr" {
  depends_on = [module.k3s_install]

  metadata {
    name = "argocd-manager-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "argocd_crb" {
  depends_on = [module.k3s_install]

  metadata {
    name = "argocd-manager-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd_cr.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd_sa.metadata[0].name
    namespace = kubernetes_service_account.argocd_sa.metadata[0].namespace
  }
}

resource "kubernetes_secret" "argocd_sa_token" {
  metadata {
    name      = "${kubernetes_service_account.argocd_sa.metadata[0].name}-token"
    namespace = kubernetes_service_account.argocd_sa.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.argocd_sa.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Add cluster to argocd
resource "argocd_cluster" "kubernetes" {
  server = "https://baku.${var.domain}:6443"
  name   = "baku"

  config {
    bearer_token = lookup(kubernetes_secret.argocd_sa_token.data, "token")

    tls_client_config {
      ca_data = base64decode(local.kubeconfig.cluster_ca_certificate)
    }
  }
}
