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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6"
    }
    # Deploy step
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}
