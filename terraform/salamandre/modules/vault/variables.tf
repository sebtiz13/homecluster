variable "ssh" {
  description = "Specify the informations for SSH connection"
  type = object({
    host            = string
    port            = number
    user            = string
    use_private_key = bool
    private_key     = string
    agent           = bool
  })

  validation {
    condition     = can(var.ssh)
    error_message = "Field ssh is required."
  }
  validation {
    condition     = can(var.ssh.host)
    error_message = "Field ssh.host is required."
  }
  validation {
    condition     = can(var.ssh.user)
    error_message = "Field ssh.user is required."
  }
  validation {
    condition     = var.ssh.agent ? true : can(var.ssh.private_key)
    error_message = "Field ssh.private_key or ssh.agent is required."
  }
}

variable "vault" {
  description = "Specify the informations for vault (note: for pod need value like `-n vault vault-0`)"
  type = object({
    token = string
    pod   = string
  })
}

variable "secrets" {
  description = "Specify the secrets want write in argocd namespace (key: path, value: map of key=value)"
  type        = map(map(string))
}
