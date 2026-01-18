#!/bin/bash
# when first argument is not set
if [ -z "$1" ]; then
    echo "No action argument is supplied eg ./make.sh deploy"
    exit 1
fi

# SETUP ANSIBLE - Install Ansible collections only (for CI/CD caching)
if [ "$1" == "setup_ansible" ]; then
  echo "Installing Ansible collections..."
  ansible-galaxy collection install -r requirements.yml
  exit 0
fi

# SETUP - Install all dependencies
if [ "$1" == "setup" ]; then
  echo "Installing Python dependencies..."
  pip install -r requirements.txt
  $0 setup_ansible
  echo "Setup complete!"
  exit 0
fi

# DEPLOY
if [ "$1" == "deploy" ]; then
# get named arguments
while [ $# -gt 0 ]; do
    if [[ $1 == --* ]]; then
        if [[ "$1" == *=* ]]; then
            v="${1/--/}"
            declare "${v%%=*}"="${v#*=}"
        else
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
    fi
    shift
done

# if vault-password not in arguments exit
if [ -z "$vault_password" ]; then
    echo "--vault_password not set"
    exit 1
fi
# check which environment should be deployed
if [ -z "$environment" ]; then
    echo "--environment not set"
    exit 1
fi
# check which service should be deployed
if [ -z "$service" ]; then
    echo "--service not set, deploying all services"
    service="all"
fi

  # Install Ansible collections before running playbook
  $0 setup_ansible

  hcloud_token=$(echo "$vault_password" | ansible-vault view hcloud_token_$environment --vault-password-file /bin/cat)
  echo "$vault_password" | HCLOUD_TOKEN=$hcloud_token ansible-playbook playbook.yml --vault-password-file /bin/cat --tags $service --skip-tags infrastructure
fi


# INFRASTRUCTURE
if [ "$1" == "infrastructure" ]; then
# get named arguments
while [ $# -gt 0 ]; do
    if [[ $1 == --* ]]; then
        if [[ "$1" == *=* ]]; then
            v="${1/--/}"
            declare "${v%%=*}"="${v#*=}"
        else
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
    fi
    shift
done

# if vault-password not in arguments exit
if [ -z "$vault_password" ]; then
    echo "--vault_password not set"
    exit 1
fi

# check that environment is production or staging
if [ "$environment" != "production" ] && [ "$environment" != "staging" ]; then
    echo "--environment must be production or staging"
    exit 1
fi

  # Install Ansible collections before running playbook
  $0 setup_ansible

  hcloud_token=$(echo "$vault_password" | ansible-vault view hcloud_token_$environment --vault-password-file /bin/cat)
  echo "$vault_password" | HCLOUD_TOKEN=$hcloud_token ansible-playbook playbook.yml --vault-password-file /bin/cat --tags infrastructure -l $environment,provision-infrastructure
fi


# KUBECONFIG
if [ "$1" == "kubeconfig" ]; then
# Parse named args
while [ $# -gt 0 ]; do
    if [[ $1 == --* ]]; then
        if [[ "$1" == *=* ]]; then
            v="${1/--/}"
            declare "${v%%=*}"="${v#*=}"
        else
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
    fi
    shift
done

# Required args
if [ -z "$vault_password" ]; then
    echo "--vault_password not set"
    exit 1
fi
if [ -z "$environment" ]; then
    echo "--environment not set"
    exit 1
fi

# Defaults
inventory="inventory.hcloud.yml"
out="${out:-$HOME/.kube/k3s-$environment.yaml}"
ssh_user="${ssh_user:-root}"

# Obtain Hetzner API token from Ansible Vault
hcloud_token=$(echo "$vault_password" | ansible-vault view hcloud_token_$environment --vault-password-file /bin/cat)
if [ -z "$hcloud_token" ]; then
  echo "Could not read hcloud_token for environment '$environment' from Ansible Vault."
  exit 1
fi

# 1) Resolve master host using dynamic inventory
if [ -z "$master_host" ]; then
  master_host=$(HCLOUD_TOKEN="$hcloud_token" ansible-inventory -i "$inventory" --list \
  | jq -r '
      (.k3s_masters.hosts[0]? // .masters.hosts[0]? // .control_plane.hosts[0]?)
      // (
        [ to_entries[]
          | select(.key != "_meta")
          | .value.hosts[]?
          | select(test("master"))
        ][0]
      )
      // empty
    ')
fi

if [ -z "$master_host" ]; then
  echo "Could not auto-detect k3s master host from inventory. Specify --master_host <name>."
  exit 1
fi

# 2) Resolve master IP from hostvars
master_ip=$(HCLOUD_TOKEN="$hcloud_token" ansible-inventory -i "$inventory" --host "$master_host" \
  | jq -r '.ansible_host // .public_ipv4 // .public_ip // empty')

if [ -z "$master_ip" ]; then
  echo "Could not resolve IP for host '$master_host'. Check your inventory or pass --master_ip."
  exit 1
fi

# 3) Copy k3s kubeconfig from the master via scp
tmpfile="$(mktemp)"
scp -o StrictHostKeyChecking=accept-new "${ssh_user}@${master_ip}:/etc/rancher/k3s/k3s.yaml" "$tmpfile"
if [ $? -ne 0 ]; then
  echo "scp of /etc/rancher/k3s/k3s.yaml from ${master_host} (${master_ip}) failed."
  rm -f "$tmpfile"
  exit 1
fi

echo "DEBUG: master_ip=$master_ip"
echo "DEBUG: Original kubeconfig server line:"
grep "server:" "$tmpfile"

# 4) Rewrite server URL from localhost to master_ip
mkdir -p "$(dirname "$out")"
sed -E "s#(server:[[:space:]]*)https://[^:]+:6443#\1https://${master_ip}:6443#g" "$tmpfile" > "$out"
rm -f "$tmpfile"

echo "DEBUG: After sed replacement:"
grep "server:" "$out"

# 5) Determine context name from master hostname
if [ -z "$context_name" ]; then
  remote_name=$(ssh -o StrictHostKeyChecking=accept-new "${ssh_user}@${master_ip}" 'hostname' 2>/dev/null | head -n1)
  # extract project prefix before first dash, e.g. about-phil-master-0-production -> about-phil
  project_name=$(echo "$remote_name" | sed -E 's/^([^-]+-[^-]+).*/\1/')
  project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g')

  if [ -z "$project_name" ]; then
    ctx="k3s-$environment"
  else
    ctx="$project_name"
  fi
else
  ctx="$context_name"
fi

# append environment if desired
if [ "${env_suffix:-true}" = "true" ] && [ -n "$environment" ]; then
  ctx="${ctx}-${environment}"
fi

# Ensure kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH. Please install kubectl to import the context."
  exit 1
fi

# Rename context, cluster, and user 'default' to our derived name
sed -i.bak \
  -e "s/name: default$/name: $ctx/g" \
  -e "s/cluster: default$/cluster: $ctx/g" \
  -e "s/user: default$/user: $ctx/g" \
  -e "s/current-context: default$/current-context: $ctx/g" \
  "$out"
rm -f "${out}.bak"

# Merge into main kubeconfig (delete old entries first to avoid conflicts)
mkdir -p "$HOME/.kube"
if [ -f "$HOME/.kube/config" ]; then
  kubectl config delete-context "$ctx" 2>/dev/null || true
  kubectl config delete-cluster "$ctx" 2>/dev/null || true
  kubectl config delete-user "$ctx" 2>/dev/null || true
fi
tmpmerged="$(mktemp)"
KUBECONFIG="$HOME/.kube/config:$out" kubectl config view --flatten > "$tmpmerged"
mv "$tmpmerged" "$HOME/.kube/config"

# Optionally make it the current context (default: true)
if [ "${make_current:-true}" = "true" ]; then
  kubectl config use-context "$ctx"
fi

echo "Wrote kubeconfig to: $out"
echo "Imported context into ~/.kube/config as: $ctx"
echo "Use it with: kubectl config use-context $ctx"
echo "NOTE: If you get x509/SAN errors, re-install k3s with: INSTALL_K3S_EXEC=\"--tls-san ${master_ip}\""
fi
