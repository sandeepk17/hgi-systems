variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "hail_cluster_id" {}
variable "count" {}

variable "security_group_ids" {
  type    = "map"
  default = {}
}

variable "key_pair_ids" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "bastion" {
  type    = "map"
  default = {}
}

resource "openstack_networking_floatingip_v2" "hail-master" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "hail-master" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "hail-${var.hail_cluster_id}-master"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["https"]}",
    "${var.security_group_ids["tcp-local"]}",
    "${var.security_group_ids["udp-local"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: hail-${var.hail_cluster_id}-master\nfqdn: hail-${var.hail_cluster_id}-master.${var.domain}"

  metadata = {
    ansible_groups = "hail-masters hail-cluster-${var.hail_cluster_id} hgi-credentials consul-agents"
    user           = "${var.image["user"]}"
    bastion_host   = "${var.bastion["host"]}"
    bastion_user   = "${var.bastion["user"]}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type         = "ssh"
      user         = "${var.image["user"]}"
      agent        = "true"
      timeout      = "2m"
      bastion_host = "${var.bastion["host"]}"
      bastion_user = "${var.bastion["user"]}"
    }
  }
}

resource "openstack_compute_floatingip_associate_v2" "hail-master" {
  provider    = "openstack"
  floating_ip = "${openstack_networking_floatingip_v2.hail-master.address}"
  instance_id = "${openstack_compute_instance_v2.hail-master.id}"
}

resource "infoblox_record" "hail-master-dns" {
  value  = "${openstack_networking_floatingip_v2.hail-master.address}"
  name   = "hail-${var.hail_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.hail-master.address}"
}

resource "openstack_blockstorage_volume_v2" "hail-master-volume" {
  name = "hail-${var.hail_cluster_id}-volume"
  size = 100
}

resource "openstack_compute_volume_attach_v2" "hail-master-volume-attach" {
  volume_id   = "${openstack_blockstorage_volume_v2.hail-master-volume.id}"
  instance_id = "${openstack_compute_instance_v2.hail-master.id}"
}
