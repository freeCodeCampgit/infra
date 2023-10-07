terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.9.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.72.0"
    }
  }
  required_version = ">= 1"
}
