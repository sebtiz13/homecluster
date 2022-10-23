data "remote_file" "kubeconfig" {
  depends_on = [null_resource.k3s_install]

  path = "/etc/rancher/k3s/k3s.yaml"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = replace(data.remote_file.kubeconfig.content, "127.0.0.1", try(var.kube_host, var.ssh.host))
  filename = var.kubeconfig_path
}
