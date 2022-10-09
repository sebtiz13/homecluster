resource "null_resource" "upgrade" {
  # Etablish SSH connection
  connection {
    type        = "ssh"
    host        = var.ssh.host
    port        = var.ssh.port
    user        = var.ssh.user
    private_key = var.ssh.use_private_key ? file(var.ssh.private_key) : null
    agent       = var.ssh.agent
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -q > /dev/null",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" dist-upgrade > /dev/null"
    ]
  }
}

resource "null_resource" "htop" {
  depends_on = [null_resource.upgrade]
  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent
  }

  lifecycle {
    create_before_destroy = true
  }

  # Etablish SSH connection
  connection {
    type        = "ssh"
    host        = self.triggers.ssh_host
    port        = self.triggers.ssh_port
    user        = self.triggers.ssh_user
    private_key = self.triggers.ssh_use_private_key ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -qy htop > /dev/null"
    ]
  }
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "sudo apt-get remove -qy htop > /dev/null"
    ]
  }
}

resource "null_resource" "curl" {
  depends_on = [null_resource.htop]
  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent
  }

  lifecycle {
    create_before_destroy = true
  }

  # Etablish SSH connection
  connection {
    type        = "ssh"
    host        = self.triggers.ssh_host
    port        = self.triggers.ssh_port
    user        = self.triggers.ssh_user
    private_key = self.triggers.ssh_use_private_key ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -qy curl > /dev/null"
    ]
  }
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "sudo apt-get remove -qy curl > /dev/null"
    ]
  }
}
