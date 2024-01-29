terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.11.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.77.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.23.0"
    }
  }
  required_version = ">= 1"
}
