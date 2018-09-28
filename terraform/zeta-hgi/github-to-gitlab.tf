module "github-to-gitlab" {
  source       = "../modules/github-to-gitlab/github-to-gitlab-v2"
  count        = 0
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  domain       = "hgi.sanger.ac.uk"
  image        = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-3ddcb29b}"
  network_name = "main"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  flavour      = "o1.small"
}
