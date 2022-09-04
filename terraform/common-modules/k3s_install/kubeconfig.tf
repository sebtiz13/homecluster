data "remote_file" "kubeconfig" {
  depends_on = [null_resource.k3s_install]

  path = "/etc/rancher/k3s/k3s.yaml"
}
