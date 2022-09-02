terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }
}
