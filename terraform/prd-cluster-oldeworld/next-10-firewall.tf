resource "linode_firewall" "prd_oldeworld_firewall_pxy" {
  label = "prd-fw-oldeworld-pxy"

  inbound {
    label    = "allow-ssh_from-anywhere"
    ports    = "22"
    protocol = "TCP"
    action   = "ACCEPT"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-http_from-nb"
    ports    = "80"
    protocol = "TCP"
    action   = "ACCEPT"
    ipv4     = ["192.168.255.0/24"]
  }

  inbound {
    label    = "allow-https_from-nb"
    ports    = "443"
    protocol = "TCP"
    action   = "ACCEPT"
    ipv4     = ["192.168.255.0/24"]
  }

  # outbound { }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = flatten([
    [for i in linode_instance.prd_oldeworld_pxy : i.id]
  ])
}

resource "linode_firewall" "prd_oldeworld_firewall" {
  label = "prd-fw-oldeworld"

  inbound {
    label    = "allow-ghost_from-anywhere"
    ports    = "32323"
    protocol = "TCP"
    action   = "ACCEPT"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-ssh_from-anywhere"
    ports    = "22"
    protocol = "TCP"
    action   = "ACCEPT"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  # outbound { }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = flatten([
    # All API nodes.
    [for i in linode_instance.prd_oldeworld_api : i.id],

    # All Client nodes.
    [for i in linode_instance.prd_oldeworld_clt : i.id],

    # All News Nodes.
    [for i in linode_instance.prd_oldeworld_nws : i.id],
  ])
}
