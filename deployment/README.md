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

# Upgrade k3s: control plane first, then workers, one node at a time
./make.sh k3s_upgrade --environment production --vault_password <pw>
```

`infrastructure` never changes the k3s version on a node that already has k3s
installed — it only reports the drift. `k3s_upgrade` is what actually moves the
cluster to the `k3s_version` pinned in the shared k3s role. Back up first, and
step only one minor version at a time (1.35 → 1.36 → 1.37, never straight to
1.37).

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
