data "linode_nodebalancer" "stg_oldeworld_nb_pxy" {
  id = 386430 # TODO: Find a way to get this ID dynamically
}

data "linode_nodebalancer_config" "stg_oldeworld_nb_pxy_config__port_443" {
  id              = 593179 # TODO: Find a way to get this ID dynamically
  nodebalancer_id = data.linode_nodebalancer.stg_oldeworld_nb_pxy.id
}

data "linode_nodebalancer_config" "stg_oldeworld_nb_pxy_config__port_80" {
  id              = 593180 # TODO: Find a way to get this ID dynamically
  nodebalancer_id = data.linode_nodebalancer.stg_oldeworld_nb_pxy.id
}

resource "linode_nodebalancer_node" "stg_oldeworld_nb_pxy_nodes__port_443" {
  count = local.pxy_node_count

  nodebalancer_id = data.linode_nodebalancer.stg_oldeworld_nb_pxy.id
  config_id       = data.linode_nodebalancer_config.stg_oldeworld_nb_pxy_config__port_443.id
  address         = "${linode_instance.stg_oldeworld_pxy[count.index].private_ip_address}:443"
  label           = "stg-node-pxy-443-${count.index}"
}

resource "linode_nodebalancer_node" "stg_oldeworld_nb_pxy_nodes__port_80" {
  count = local.pxy_node_count

  nodebalancer_id = data.linode_nodebalancer.stg_oldeworld_nb_pxy.id
  config_id       = data.linode_nodebalancer_config.stg_oldeworld_nb_pxy_config__port_80.id
  address         = "${linode_instance.stg_oldeworld_pxy[count.index].private_ip_address}:80"
  label           = "stg-node-pxy-80-${count.index}"
}

resource "linode_domain_record" "stg_oldeworld_nb_pxy_dnsrecord__public" {
  domain_id   = data.linode_domain.ops_dns_domain.id
  name        = "oldeworld.stg.${var.network_subdomain}"
  record_type = "A"
  target      = data.linode_nodebalancer.stg_oldeworld_nb_pxy.ipv4
  ttl_sec     = 120
}
