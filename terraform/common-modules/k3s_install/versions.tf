terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.1.0"
    }
    # kubeconfig
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3"
    }
  }
}
