variable "environment" {
  description = "Specify the environment of running terraform"
  type = string
  default = "production"

  validation {
    condition = var.environment == "vm" || var.environment == "production"
    error_message = "Field environment must be equal to `vm` or `production`."
  }
}

##
# SSH config
##
variable "ssh_host" {
  description = "Specify the SSH host"
  type        = string
}
variable "ssh_port" {
  description = "Specify the SSH port"
  type        = number
  default     = 22
}
variable "ssh_user" {
  description = "Specify the SSH user"
  type        = string
}
variable "ssh_key" {
  description = "Specify the SSH key. Can keep empty if `ssh_use_agent` is set to true"
  type        = string
  default     = null
}
variable "ssh_use_agent" {
  description = "Specify the state of using SSH agent. This need to be `true` for using passphrased SSH key"
  type        = bool
  default     = false
}
