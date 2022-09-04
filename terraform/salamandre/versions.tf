terraform {
  required_providers {
    # Setup step
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.0.25"
    }
    # Deploy step
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}
