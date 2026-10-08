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

## Shared-cluster projects

Bootstrap one cluster owner with `--shared-cluster` and export its public
connection descriptor with `startup cluster export`. Additional startups use
`startup bootstrap --cluster <descriptor>` and deploy into their own namespaces.
Their `deployment/cluster.yml` records the cluster identity and owner; keep it
and the ownership settings in `group_vars/all.yml` committed. The owner manages nodes and cluster
upgrades. Attached projects only deploy and operate their own application data.

Namespaces receive default resource limits, quotas and network policies. Review
these settings before adding workloads. The deployment SSH key retains server
administrator access, so use this mode only for mutually trusted projects.
Postgres and media use local node storage and need verified per-project backups.
Shared cluster failures affect all attached applications.

The Copier `deploy_ref` answer selects the shared workflow ref. Bootstrap's
`--deployment-ref` exposes it for a reviewed branch or commit. It defaults to
`main`, preserving existing workflow references.
