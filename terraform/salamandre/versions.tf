terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.0.25"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 3.2.1"
    }
  }
}
