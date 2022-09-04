# Provider for k3s_install
provider "remote" {
  conn {
    host             = local.ssh_connection.host
    port             = local.ssh_connection.port
    user             = local.ssh_connection.user
    private_key_path = local.ssh_connection.use_private_key ? local.ssh_connection.private_key : null
    agent            = local.ssh_connection.agent
    sudo             = true
  }
}


# Provider for kubernetes apps
provider "helm" {
  kubernetes {
    host = local.kubeconfig.host

    cluster_ca_certificate = base64decode(local.kubeconfig.cluster_ca_certificate)
    client_certificate     = base64decode(local.kubeconfig.client_certificate)
    client_key             = base64decode(local.kubeconfig.client_key)
  }
}

provider "kubernetes" {
  host = local.kubeconfig.host

  cluster_ca_certificate = base64decode(local.kubeconfig.cluster_ca_certificate)
  client_certificate     = base64decode(local.kubeconfig.client_certificate)
  client_key             = base64decode(local.kubeconfig.client_key)
}


provider "argocd" {
  server_addr                 = "localhost:8443"
  insecure                    = true
  port_forward                = true
  port_forward_with_namespace = local.argocd_namespace
  username                    = "admin"
  password                    = var.argocd_admin_password

  kubernetes {
    host = local.kubeconfig.host

    cluster_ca_certificate = base64decode(local.kubeconfig.cluster_ca_certificate)
    client_certificate     = base64decode(local.kubeconfig.client_certificate)
    client_key             = base64decode(local.kubeconfig.client_key)
  }
}
