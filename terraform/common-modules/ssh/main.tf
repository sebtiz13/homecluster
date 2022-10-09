resource "null_resource" "config" {
  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent

    port = var.port
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

  provisioner "file" {
    content = templatefile("${path.module}/config.conf.tftpl", {
      port = self.triggers.port
    })
    destination = "/etc/ssh/sshd_config.d/10-custom.conf"
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "sudo rm /etc/ssh/sshd_config.d/10-custom.conf"
    ]
  }
}

resource "null_resource" "create_user" {
  for_each = var.users

  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent

    username       = each.key
    authorized_key = each.value.authorized_key
    sudoer         = each.value.sudoer
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

  provisioner "remote-exec" {
    inline = [
      // Create user
      "sudo useradd -m ${self.triggers.username}",
      // Add authorized_key
      "sudo mkdir -p /home/${self.triggers.username}/.ssh",
      "sudo echo \"${self.triggers.authorized_key}\" > /home/${self.triggers.username}/.ssh/authorized_keys",
      // Set permissions to directory `.ssh`
      "sudo chown -R ${self.triggers.username}:${self.triggers.username} /home/${self.triggers.username}/.ssh",
      "sudo chmod 700 /home/${self.triggers.username}/.ssh",
      "sudo chmod 600 /home/${self.triggers.username}/.ssh/authorized_keys",
      // Add sudo group if is enable
      self.triggers.sudoer ? "usermod -a -G sudo ${self.triggers.username}" : ""
    ]
  }
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      // Delete user
      "sudo deluser --remove-home ${self.triggers.username}"
    ]
  }
}
