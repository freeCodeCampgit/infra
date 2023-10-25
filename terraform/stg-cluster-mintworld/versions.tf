terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.9.3"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.75.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.17.0"
    }
  }
  required_version = ">= 1"
}
