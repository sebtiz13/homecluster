# Apps variables
locals {
  base_domain     = "sebtiz13.fr"
  tls_secret_name = replace(local.base_domain, ".", "-")

  clusters = {
    salamandre = "https://kubernetes.default.svc"
    baku       = "https://${var.environment == "vm" ? "baku.vm" : "baku." + local.base_domain}:6443"
  }
  core_apps = {
    project = "cluster-core-apps"
    cluster = local.clusters.salamandre
  }

  ssh_connection = {
    host        = var.ssh_host
    port        = var.ssh_port
    user        = var.ssh_user
    private_key = var.ssh_key
    agent       = var.ssh_use_agent
  }
}

module "apt" {
  source = "../common-modules/apt"
  ssh    = local.ssh_connection
}

module "k3s_install" {
  source = "../common-modules/k3s_install"

  depends_on_ = [module.apt]
  ssh         = local.ssh_connection
  k3s_flags = [
    "--disable traefik"
  ]
}
locals {
  kubeconfig = module.k3s_install.kubeconfig
}

module "ssh" {
  source = "../common-modules/ssh"

  depends_on_ = [module.apt]
  ssh         = local.ssh_connection
  users       = var.users
}
