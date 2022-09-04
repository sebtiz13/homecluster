

output "kubeconfig" {
  depends_on = [data.remote_file.kubeconfig]

  description = "The kubeconfig of the cluster."
  sensitive   = true
  value = {
    host                   = "${replace(yamldecode(data.remote_file.kubeconfig.content).clusters.0.cluster.server, "127.0.0.1", try(var.kube_host, var.ssh.host))}"
    cluster_ca_certificate = "${yamldecode(data.remote_file.kubeconfig.content).clusters.0.cluster.certificate-authority-data}"
    client_certificate     = "${yamldecode(data.remote_file.kubeconfig.content).users.0.user.client-certificate-data}"
    client_key             = "${yamldecode(data.remote_file.kubeconfig.content).users.0.user.client-key-data}"
  }
}
