variable "ssh" {
  description = "Specify the informations for SSH connection"
  type = object({
    host        = string
    port        = number
    user        = string
    private_key = string
    agent       = bool
  })
  default = null

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

variable "pool_name" {
  description = "Specify the pool name"
  type        = string
  default     = "data"
}

variable "pool_type" {
  description = "Specify the pool type (stripe, mirror, raidz (similar to RAID5) or raidz2 (Similar to RAID5 with dual parity))"
  type = string
  default = "raidz"

  validation {
    condition = var.pool_type == "stripe" || var.pool_type == "mirror" || var.pool_type == "raidz" || var.pool_type == "raidz2"
    error_message = "Field pool_type must be equal to `stripe`, `mirror`, `raidz` or `raidz2`."
  }
}

variable "pool_disks" {
  description = "Specify the pool disks"
  type        = list(string)
}
