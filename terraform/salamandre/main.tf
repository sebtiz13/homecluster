# Apps variables
locals {
  out_dir         = "../../out"
  kubeconfig_path = "${local.out_dir}/kubeconfig/salamandre.${var.environment}.yaml"

  labeled_namespaces = [
    local.argocd_namespace,
    local.vault_namespace,
    local.keycloak_namespace,
    local.minio_namespace,
    local.gitlab_namespace
  ]
  domains = [
    local.argocd_host,
    local.vault_host,
    local.keycloak_host,
    local.minio_host,
    local.gitlab_host,
    local.gitlab_kas_host
  ]
  excluded_apps = split(",", var.excluded_apps)

  clusters = {
    salamandre = "https://kubernetes.default.svc"
    baku       = "https://baku.${var.domain}:6443"
  }

  ssh_connection = {
    host            = var.ssh_host
    port            = var.ssh_port
    user            = var.ssh_user
    use_private_key = try(length(var.ssh_key) > 0, fileexists(var.ssh_key), false)
    private_key     = var.ssh_key
    agent           = var.ssh_use_agent
  }
}

module "apt" {
  source = "../common-modules/apt"
  ssh    = local.ssh_connection
}

module "k3s_install" {
  source = "../common-modules/k3s_install"

  depends_on = [module.apt]
  ssh        = local.ssh_connection
  k3s_flags = [
    "--disable traefik"
  ]
  k3s_node_name = "salamandre"

  kube_host       = var.ssh_host
  kubeconfig_path = local.kubeconfig_path
}
locals {
  kubeconfig = module.k3s_install.kubeconfig
}

module "ssh" {
  source = "../common-modules/ssh"

  depends_on = [module.apt]
  ssh        = local.ssh_connection
  users      = var.users
  port       = var.environment == "vm" ? var.ssh_port : 8474
}

module "zfs" {
  source = "../common-modules/zfs"

  depends_on = [module.apt]
  ssh        = local.ssh_connection
  pool_disks = var.zpool_disks
}
