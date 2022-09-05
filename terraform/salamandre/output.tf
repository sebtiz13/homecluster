output "argocd_admin_password" {
  depends_on = [data.kubernetes_secret.argocd_admin_password]

  description = "The admin password for argocd."
  sensitive   = true
  value       = data.kubernetes_secret.argocd_admin_password.data.password
}


output "keycloack_admin_password" {
  depends_on = [random_password.keycloack_admin_password]

  description = "The admin password for keycloack."
  sensitive   = true
  value       = local.keycloack_admin_password
}
