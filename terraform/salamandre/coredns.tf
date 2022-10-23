resource "kubernetes_config_map" "custom-config" {
  metadata {
    name      = "coredns-custom"
    namespace = "kube-system"
  }

  data = {
    "salamandre.server" = "${templatefile("${path.module}/values/coredns/salamandre.server.tftpl", {
      server_ip = local.ssh_connection.host
    })}"
    "sebtiz13.server" = "${templatefile("${path.module}/values/coredns/sebtiz13.server.tftpl", {
      base_domain = var.domain
      server_ip   = local.ssh_connection.host
      domains     = local.domains
    })}"
  }
}

resource "null_resource" "coredns-reload" {
  depends_on = [kubernetes_config_map.custom-config]

  // Etablish SSH connection
  connection {
    type        = "ssh"
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.use_private_key ? file(local.ssh_connection.private_key) : null
    agent       = local.ssh_connection.agent
  }

  // Restart coredns if is already started
  provisioner "remote-exec" {
    script = "${path.module}/scripts/reboot-coredns.sh"
  }
}
