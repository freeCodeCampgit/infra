terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.9.3"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.74.1"
    }
  }
  required_version = ">= 1"
}
