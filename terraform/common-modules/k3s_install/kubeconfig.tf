data "remote_file" "kubeconfig" {
  depends_on = [null_resource.k3s_install]

  path = "/etc/rancher/k3s/k3s.yaml"
}

resource "local_sensitive_file" "kubeconfig" {
  # Replace url and cluster name
  content = replace(
    replace(data.remote_file.kubeconfig.content, "127.0.0.1", try(var.kube_host, var.ssh.host)),
    "default",
    var.k3s_node_name
  )
  filename = var.kubeconfig_path
}
