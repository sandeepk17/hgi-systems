module "spark-master-ks20" {
  source = "../modules/spark-master"
  count  = 1

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.large"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  extra_ansible_groups = ["consul-cluster-delta-hgi"]
  spark_cluster_id     = "ks20"
}

module "spark-compute-ks20" {
  source = "../modules/spark-compute"
  count  = 0

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.large"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  extra_ansible_groups = ["consul-cluster-delta-hgi"]
  spark_cluster_id     = "ks20"
}
