resource "null_resource" "install" {
  triggers = {
    ssh_host        = var.ssh.host
    ssh_port        = var.ssh.port
    ssh_user        = var.ssh.user
    ssh_private_key = var.ssh.private_key
    ssh_agent       = var.ssh.agent
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
    private_key = can(self.triggers.ssh_private_key) ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [
      // Enable `contrib` package repository
      "sudo sed -r -i 's/^deb(.*)$/deb\\1 contrib/g' /etc/apt/sources.list",
      "sudo apt-get update -q > /dev/null",
      // Install ZFS filesystem dependencies
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -qy linux-headers-$(uname -r) linux-image-amd64 spl kmod > /dev/null",
      // Install ZFS filesystem
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" zfsutils-linux zfs-dkms zfs-zed > /dev/null",
    ]
  }
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      // Remove packages
      "sudo apt-get remove -qy zfsutils-linux zfs-dkms zfs-zed linux-headers-$(uname -r) linux-image-amd64 spl kmod",
    ]
  }
}

resource "null_resource" "create_pool" {
  depends_on = [null_resource.install]

  triggers = {
    ssh_host        = var.ssh.host
    ssh_port        = var.ssh.port
    ssh_user        = var.ssh.user
    ssh_private_key = var.ssh.private_key
    ssh_agent       = var.ssh.agent

    name  = var.pool_name
    type  = var.pool_type
    disks = join(" ", var.pool_disks)
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
    private_key = can(self.triggers.ssh_private_key) ? file(self.triggers.ssh_private_key) : null
    agent       = self.triggers.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [
      // Create pool
      "sudo zpool create ${self.triggers.name} ${self.triggers.type} ${self.triggers.disks}"
    ]
  }
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      // Delete pool
      "sudo zpool destroy ${self.triggers.name}"
    ]
  }
}
