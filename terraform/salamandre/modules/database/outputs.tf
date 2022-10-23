output "password" {
  description = "Generated database password"
  sensitive   = true
  value       = random_password.password.result
}
