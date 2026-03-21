# Deployment

## Quick Start

```bash
# Setup shared roles and dependencies
./make.sh setup_ansible

# Deploy infrastructure (creates Hetzner servers, K3s, DNS)
./make.sh infrastructure --environment production --vault_password <pw>

# Deploy services
./make.sh deploy --environment production --vault_password <pw>

# Get kubeconfig for kubectl access
./make.sh kubeconfig --environment production --vault_password <pw>
```

## Secrets Management

```bash
# List vault files
./make.sh list_vaults

# Update secrets
./make.sh secrets_update -p <vault_password> --field-random backend_db_password

# Rotate vault password
./make.sh rotate_vault_password --old-password <old> --new-password <new>
```
