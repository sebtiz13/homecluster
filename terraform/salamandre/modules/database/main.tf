resource "random_password" "password" {
  length  = 16
  special = false
}

resource "null_resource" "database" {
  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent

    username = var.username
    database = var.database
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

  // Create database access
  provisioner "remote-exec" {
    inline = [
      "sudo -u postgres -H -- psql -c \"CREATE USER ${self.triggers.username} WITH PASSWORD '${random_password.password.result}';\" > /dev/null",
      "sudo -u postgres -H -- psql -c \"CREATE DATABASE ${self.triggers.database} OWNER ${self.triggers.username};\" > /dev/null",
      "sudo -u postgres -H -- psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${self.triggers.database} TO ${self.triggers.username};\" > /dev/null"
    ]
  }

  // Delete database access
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "sudo -u postgres -H -- psql -c \"DROP DATABASE ${self.triggers.database};\" > /dev/null",
      "sudo -u postgres -H -- psql -c \"DROP USER ${self.triggers.username};\" > /dev/null"
    ]
  }
}
