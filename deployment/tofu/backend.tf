# Provider-agnostic remote state (S3-compatible object storage).
#
# Empty/partial on purpose — backend config can't use variables. The CLI renders
# backend.<env>.hcl per environment (Hetzner or, later, OVH endpoint) and runs
#   tofu init -backend-config=backend.<env>.hcl
# Object-storage credentials come from the vault as AWS_ACCESS_KEY_ID/SECRET.
#
# Without a backend.<env>.hcl the CLI inits with -backend=false (local state),
# so a project can run before a state bucket exists.

terraform {
  backend "s3" {}
}
