resource "linode_instance" "stg_oldeworld_jms" {
  count = local.jms_node_count
  label = "stg-vm-oldeworld-jms-${count.index + 1}"

  region           = var.region
  type             = "g6-standard-2"
  private_ip       = true
  watchdog_enabled = true

  # NOTE:
  # Value should use '_' as sepratator for compatibility with Ansible Dynamic Inventory
  tags = ["stg", "oldeworld", "jms"]

  # WARNING:
  # Do not change, will delete and recreate all instances in the group
  # NOTE:
  # Value should use '_' as sepratator for compatibility with Ansible Dynamic Inventory
  group = "stg_oldeworld_jms"
}

resource "linode_instance_disk" "stg_oldeworld_jms_disk__boot" {
  count     = local.jms_node_count
  label     = "stg-vm-oldeworld-jms-${count.index + 1}-boot"
  linode_id = linode_instance.stg_oldeworld_jms[count.index].id
  size      = linode_instance.stg_oldeworld_jms[count.index].specs.0.disk

  image     = data.hcp_packer_image.linode_ubuntu.cloud_image_id
  root_pass = var.password

  stackscript_id = data.linode_stackscripts.cloudinit_scripts.stackscripts.0.id
  stackscript_data = {
    userdata = base64encode(
      templatefile("${path.root}/cloud-init--userdata.yml.tftpl", {
        tf_hostname = "jms-${count.index + 1}.oldeworld.stg.${data.linode_domain.ops_dns_domain.domain}"
      })
    )
  }
}

resource "linode_instance_config" "stg_oldeworld_jms_config" {
  count     = local.jms_node_count
  label     = "stg-vm-oldeworld-jms-config"
  linode_id = linode_instance.stg_oldeworld_jms[count.index].id

  devices {
    sda {
      disk_id = linode_instance_disk.stg_oldeworld_jms_disk__boot[count.index].id
    }
  }

  # eth0 is the public interface.
  interface {
    purpose = "public"
  }

  # eth1 is the private interface.
  interface {
    purpose = "vlan"
    label   = "stg-oldeworld-vlan"
    # Request the host IP for the machine
    ipam_address = "${cidrhost("10.0.0.0/8", local.ipam_block_jms + count.index)}/24"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = var.password
    host     = linode_instance.stg_oldeworld_jms[count.index].ip_address
  }

  # All of the provisioning should be done via cloud-init.
  # This is just to setup the reboot.
  provisioner "remote-exec" {
    inline = [
      # Wait for cloud-init to finish.
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "echo Current hostname...; hostname",
      "shutdown -r +1 'Terraform: Rebooting to apply hostname change in 1 min.'"
    ]
  }

  # This run is a hack to trigger the reboot,
  # which may fail otherwise in the previous step.
  provisioner "remote-exec" {
    inline = [
      "uptime"
    ]
  }

  helpers {
    updatedb_disabled = true
  }

  kernel = "linode/grub2"
  booted = true
}

resource "linode_domain_record" "stg_oldeworld_jms_dnsrecord__vlan" {
  count = local.jms_node_count

  domain_id   = data.linode_domain.ops_dns_domain.id
  name        = "jms-${count.index + 1}.oldeworld.stg"
  record_type = "A"
  target      = trimsuffix(linode_instance_config.stg_oldeworld_jms_config[count.index].interface[1].ipam_address, "/24")
  ttl_sec     = 120
}

resource "linode_domain_record" "stg_oldeworld_jms_dnsrecord__public" {
  count = local.jms_node_count

  domain_id   = data.linode_domain.ops_dns_domain.id
  name        = "pub.jms-${count.index + 1}.oldeworld.stg.${var.network_subdomain}"
  record_type = "A"
  target      = linode_instance.stg_oldeworld_jms[count.index].ip_address
  ttl_sec     = 120
}

resource "linode_domain_record" "stg_oldeworld_jms_dnsrecord__private" {
  count = local.jms_node_count

  domain_id   = data.linode_domain.ops_dns_domain.id
  name        = "prv.jms-${count.index + 1}.oldeworld.stg"
  record_type = "A"
  target      = linode_instance.stg_oldeworld_jms[count.index].private_ip_address
  ttl_sec     = 120
}

resource "akamai_dns_record" "stg_oldeworld_jms_dnsrecord__vlan" {
  count = local.jms_node_count

  zone       = local.zone
  recordtype = "A"
  ttl        = 120

  name   = "jms-${count.index + 1}.oldeworld.stg.${local.zone}"
  target = [trimsuffix(linode_instance_config.stg_oldeworld_jms_config[count.index].interface[1].ipam_address, "/24")]
}

resource "akamai_dns_record" "stg_oldeworld_jms_dnsrecord__public" {
  count = local.jms_node_count

  zone       = local.zone
  recordtype = "A"
  ttl        = 120

  name   = "pub.jms-${count.index + 1}.oldeworld.stg.${var.network_subdomain}.${local.zone}"
  target = [linode_instance.stg_oldeworld_jms[count.index].ip_address]
}

resource "akamai_dns_record" "stg_oldeworld_jms_dnsrecord__private" {
  count = local.jms_node_count

  zone       = local.zone
  recordtype = "A"
  ttl        = 120

  name   = "prv.jms-${count.index + 1}.oldeworld.stg.${local.zone}"
  target = [linode_instance.stg_oldeworld_jms[count.index].private_ip_address]
}