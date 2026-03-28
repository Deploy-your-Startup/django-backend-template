# Deployment

## Quick Start

```bash
# Sync the shared deploy repository into your GitHub account
./make.sh sync

# Download shared roles and install deployment dependencies
./make.sh setup

# Deploy infrastructure (creates Hetzner servers, K3s, DNS)
./make.sh infrastructure --environment production --vault_password <pw>

# Deploy services
./make.sh deploy --environment production --vault_password <pw>

# Get kubeconfig for kubectl access
./make.sh kubeconfig --environment production --vault_password <pw>
```

`ci_ssh_key` and `hcloud_token_production` are generated during bootstrap,
stored as vaulted files in `deployment/`, and rotated to the project-specific
vault password automatically.

## Secrets Management

```bash
# List vault files
./make.sh list_vaults

# Update secrets
./make.sh secrets_update -p <vault_password> --field-random backend_db_password

# Rotate vault password
./make.sh rotate_vault_password --old-password <old> --new-password <new>
```
