locals {
  salamandre_credentials = sensitive(jsondecode(file("${local.out_dir}/credentials/salamandre.${var.environment}.json")))
}

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
provider "kubectl" {
  alias          = "salamandre"
  config_path    = "${local.out_dir}/kubeconfig/salamandre.${var.environment}.yaml"
  config_context = "salamandre"
}

provider "kubernetes" {
  host = local.kubeconfig.host

  cluster_ca_certificate = base64decode(local.kubeconfig.cluster_ca_certificate)
  client_certificate     = base64decode(local.kubeconfig.client_certificate)
  client_key             = base64decode(local.kubeconfig.client_key)
}

provider "argocd" {
  server_addr = "argocd.${var.domain}:443"
  username    = "admin"
  password    = local.salamandre_credentials.argocd_admin_password
}

provider "vault" {
  address = "https://vault-secrets.${var.domain}"
  token   = local.salamandre_credentials.vault.root_token
}
