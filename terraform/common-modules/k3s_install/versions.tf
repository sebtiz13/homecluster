terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
    http = {
      source = "hashicorp/http"
      version = "~> 2.1"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.0.25"
    }
  }
}
