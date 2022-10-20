resource "kubernetes_namespace" "labeled_namespace" {
  depends_on = [module.k3s_install]
  for_each   = toset(local.labeled_namespaces)

  metadata {
    name = each.key
    labels = {
      name   = each.key
      domain = var.domain
    }
  }
}
