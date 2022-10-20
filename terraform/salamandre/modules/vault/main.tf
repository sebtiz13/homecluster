resource "null_resource" "vault" {
  # Etablish SSH connection
  connection {
    type        = "ssh"
    host        = var.ssh.host
    port        = var.ssh.port
    user        = var.ssh.user
    private_key = var.ssh.use_private_key ? file(var.ssh.private_key) : null
    agent       = var.ssh.agent
  }

  provisioner "file" {
    content = templatefile("${path.module}/script.sh", {
      token = var.vault.token

      secrets = {
        for path, values in var.secrets : "${path}" =>
        join(" ", formatlist("%s=\"%s\"", keys(values), values(values)))
      }
    })
    destination = "/tmp/${null_resource.vault.id}"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl exec ${var.vault.pod} -- /bin/sh -c \"`cat /tmp/${null_resource.vault.id}`\" > /dev/null"
    ]
  }
}
