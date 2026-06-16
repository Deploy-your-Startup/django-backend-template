# Infrastructure provisioning for this project.
#
# Run by `startup ansible infrastructure` (= make.sh infrastructure), which sets
# the TF_VAR_* values from this project's group_vars and HCLOUD_TOKEN from the
# vault. The Hetzner module lives in the shared deploy-template, exported to
# .shared-roles/tofu at deploy time.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.56.0"
    }
  }
}

provider "hcloud" {}

module "infra" {
  source = "../.shared-roles/tofu/modules/hetzner"

  project_name = var.project_name
  master_count = var.master_count
  worker_count = var.worker_count
  location     = var.location
  server_type  = var.server_type

  ssh_public_keys = var.ssh_public_keys

  create_load_balancer = var.create_load_balancer

  base_domain        = var.base_domain
  additional_domains = var.additional_domains
  dns_apex_wildcard  = var.dns_apex_wildcard
  extra_dns_records  = var.extra_dns_records
}
