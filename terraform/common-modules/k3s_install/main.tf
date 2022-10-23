locals {
  // Generate a map of all calculed server fields, used during k3s installation.
  server_flags = join(" ", compact(concat(
    [
      "--node-name='${var.k3s_node_name}'",
      "--tls-san ${var.kube_host}",
      "--write-kubeconfig-mode=644"
    ],
    try(var.k3s_flags, [])
  )))
}

resource "null_resource" "k3s_install" {
  triggers = {
    ssh_host            = var.ssh.host
    ssh_port            = var.ssh.port
    ssh_user            = var.ssh.user
    ssh_use_private_key = var.ssh.use_private_key
    ssh_private_key     = var.ssh.private_key
    ssh_agent           = var.ssh.agent

    k3s_version   = local.k3s_version
    k3s_node_name = var.k3s_node_name
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

  // Upload k3s file
  provisioner "file" {
    content     = data.http.k3s_installer.response_body
    destination = "/tmp/k3s-installer"
  }

  // Install k3s server
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing K3S ${self.triggers.k3s_version}...'",
      // Install k3s server
      "INSTALL_K3S_VERSION=${self.triggers.k3s_version} sh /tmp/k3s-installer server ${local.server_flags} > /dev/null",
      // Wait k3s started
      "until kubectl get node ${self.triggers.k3s_node_name} &> /dev/null; do sleep 1; done"
    ]
  }

  // Remove k3s
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "sudo /usr/local/bin/k3s-uninstall.sh > /dev/null"
    ]
  }
}
