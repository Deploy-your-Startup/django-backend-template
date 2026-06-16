# Values are supplied by the CLI as TF_VAR_* from this project's group_vars.
# Defaults here match the Ansible role defaults for vars not kept in group_vars
# (server_type, location).

variable "project_name" {
  type = string
}

variable "master_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 0
}

variable "location" {
  type    = string
  default = "fsn1"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "ssh_public_keys" {
  type = list(object({
    name = string
    key  = string
  }))
}

variable "create_load_balancer" {
  type    = bool
  default = false
}

variable "base_domain" {
  type = string
}

variable "additional_domains" {
  type    = list(string)
  default = []
}

variable "dns_apex_wildcard" {
  type    = bool
  default = true
}

variable "extra_dns_records" {
  type = map(list(object({
    name  = string
    type  = string
    ttl   = number
    value = string
  })))
  default = {}
}
