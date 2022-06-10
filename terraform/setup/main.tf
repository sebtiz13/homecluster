# Apps variables
locals {
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
