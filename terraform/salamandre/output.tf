output "argocd_admin_password" {
  depends_on = [data.kubernetes_secret.argocd_admin_password]

  description = "The admin password for argocd."
  sensitive   = true
  value       = data.kubernetes_secret.argocd_admin_password.data.password
}


output "keycloak_admin_password" {
  depends_on = [random_password.keycloak_admin_password]

  description = "The admin password for keycloak."
  sensitive   = true
  value       = local.keycloak_admin_password
}
