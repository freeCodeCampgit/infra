locals {
  zone = "freecodecamp.net"
}

data "cloudflare_zone" "cf_zone" {
  name = local.zone
}

# This data source depends on the stackscript resource
# which is created in terraform/ops-stackscripts/main.tf
data "linode_stackscripts" "cloudinit_scripts" {
  filter {
    name   = "label"
    values = ["CloudInitfreeCodeCamp"]
  }
  filter {
    name   = "is_public"
    values = ["false"]
  }
}
data "hcp_packer_artifact" "linode_ubuntu_artifact" {
  platform     = "linode"
  bucket_name  = "linode-ubuntu"
  region       = "us-east"
  channel_name = "latest"
}

locals {
  consul_svr_count  = 3
  nomad_svr_count   = 3
  cluster_wkr_count = 5
}

locals {
  ipam_block_consul_svr  = 10 # 10.0.0.10, 10.0.0.11, ...
  ipam_block_nomad_svr   = 30 # 10.0.0.30, 10.0.0.31, ...
  ipam_block_cluster_wkr = 50 # 10.0.0.50, 10.0.0.51, ...
}
