terraform {
  required_providers {
    # Setup step
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.1"
    }
    # Deploy step
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 4.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.10"
    }
  }
}
