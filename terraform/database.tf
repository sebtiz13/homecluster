
resource "null_resource" "postgresql_install" {
  depends_on = [module.apt]
  triggers = {
    ssh_host        = local.ssh_connection.host
    ssh_port        = local.ssh_connection.port
    ssh_user        = local.ssh_connection.user
    ssh_private_key = local.ssh_connection.private_key
    ssh_agent       = local.ssh_connection.agent

    pg_version = var.pg_version
    server_ip  = local.ssh_connection.host
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
    private_key = self.triggers.ssh_private_key ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  // Install postgresql
  provisioner "remote-exec" {
    inline = [
      // Retrieve server ip
      "export PG_SERVER_IP=$(printf \"%-23s\" \"$(ip route get 1 | awk '{print $(NF-2);exit}')/32\")",
      // Install packages
      "sudo apt install postgresql-${self.triggers.pg_version} postgresql-client-${self.triggers.pg_version} -y > /dev/null",
      // Add host for kubernetes cluster access
      "sudo sed -i \"\\|^# IPv6 local connections:.*|i host    all             all             $PG_SERVER_IP md5\" /etc/postgresql/${self.triggers.pg_version}/main/pg_hba.conf",
      // Start postgresql
      "sudo pg_ctlcluster ${self.triggers.pg_version} main start",
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
      "sudo sed -i \"\\|host    all             all             $PG_SERVER_IP md5|d\" /etc/postgresql/${self.triggers.pg_version}/main/pg_hba.conf",
      // Remove host
      "sudo sed -i '\\|127\\.0\\.0\\.1 postgresql\\.loc|d' /etc/hosts",
      // Remove packages
      "sudo apt remove postgresql-${self.triggers.pg_version} postgresql-client-${self.triggers.pg_version} -y > /dev/null"
    ]
  }
}
