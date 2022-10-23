locals {
  pg_local_cidr = coalesce(var.pg_local_cidr, "${cidrhost("${local.ssh_connection.host}/24", 0)}/24")
  pg_listen_connections = join("\\n", [
    format("%-7s %-15s %-15s %-23s %s", "host", "all", "all", "10.42.0.0/24", "md5"),
    format("%-7s %-15s %-15s %-23s %s", "host", "all", "all", local.pg_local_cidr, "md5")
  ])
  pg_config_folder = "/etc/postgresql/${var.pg_version}/main"
}

resource "null_resource" "postgresql_install" {
  depends_on = [module.zfs]
  triggers = {
    ssh_host            = local.ssh_connection.host
    ssh_port            = local.ssh_connection.port
    ssh_user            = local.ssh_connection.user
    ssh_use_private_key = local.ssh_connection.use_private_key
    ssh_private_key     = local.ssh_connection.private_key
    ssh_agent           = local.ssh_connection.agent

    pg_version            = var.pg_version
    pg_listen_connections = local.pg_listen_connections
    pg_config_folder      = local.pg_config_folder
  }

  lifecycle {
    create_before_destroy = true
  }

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = self.triggers.ssh_host
    port        = self.triggers.ssh_port
    user        = self.triggers.ssh_user
    private_key = self.triggers.ssh_use_private_key ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  // Install postgresql
  provisioner "remote-exec" {
    inline = [
      // Install packages
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -qy postgresql-${self.triggers.pg_version} postgresql-client-${self.triggers.pg_version} > /dev/null",
      // Allow connection from kubernetes cluster and local network
      "sudo sed -i \"s/#listen_addresses = 'localhost'/${format("%-31s", "listen_addresses = '*'")}/\" ${self.triggers.pg_config_folder}/postgresql.conf",
      "sudo sed -i \"\\|^# IPv6 local connections:.*|i ${self.triggers.pg_listen_connections}\" ${self.triggers.pg_config_folder}/pg_hba.conf",
      // Start postgresql
      "sudo pg_ctlcluster ${self.triggers.pg_version} main restart",
      // Add database host
      "echo \"127.0.0.1 postgresql.loc\" | sudo tee -a /etc/hosts > /dev/null"
    ]
  }

  // Remove postgresql
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      // Remove config line
      "sudo sed -i \"\\|${self.triggers.pg_listen_connections}|d\" ${self.triggers.pg_config_folder}/pg_hba.conf",
      // Remove host
      "sudo sed -i '\\|127\\.0\\.0\\.1 postgresql\\.loc|d' /etc/hosts",
      // Remove packages
      "sudo apt-get remove -qy postgresql-${self.triggers.pg_version} postgresql-client-${self.triggers.pg_version} > /dev/null"
    ]
  }
}
