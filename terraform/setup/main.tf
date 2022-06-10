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
  ssh = local.ssh_connection
}
