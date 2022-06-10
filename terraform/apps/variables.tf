variable "environment" {
  description = "Specify the environment of running terraform"
  type = string
  default = "production"

  validation {
    condition = var.environment == "vm" || var.environment == "production"
    error_message = "Field environment must be equal to `vm` or `production`."
  }
}

variable "kubeconfig" {
  description = "Specify the kubeconfig data"
  type = object({
    host                   = string
    cluster_ca_certificate = string
    client_certificate     = string
    client_key             = string
  })
  sensitive = true

  validation {
    condition     = can(var.kubeconfig)
    error_message = "Field kubeconfig is required."
  }
  validation {
    condition     = length(var.kubeconfig.host) > 0
    error_message = "Field kubeconfig.host is required."
  }
  validation {
    condition     = length(var.kubeconfig.cluster_ca_certificate) > 0
    error_message = "Field kubeconfig.cluster_ca_certificate is required."
  }
  validation {
    condition     = length(var.kubeconfig.client_certificate) > 0
    error_message = "Field kubeconfig.client_certificate is required."
  }
  validation {
    condition     = length(var.kubeconfig.client_key) > 0
    error_message = "Field kubeconfig.client_key is required."
  }
}

##
# Apps variables
##
variable "chart_versions" {
  description = "Specify the chart versions"
  type = object({
    argocd = string
  })
  default = null
}
