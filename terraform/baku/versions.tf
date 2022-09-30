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
  }
}
