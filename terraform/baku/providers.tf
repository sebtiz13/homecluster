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
  alias            = "salamandre"
  load_config_file = false
  config_path      = "${local.out_dir}/kubeconfig/salamndrere.${var.environment}.yaml"
}
