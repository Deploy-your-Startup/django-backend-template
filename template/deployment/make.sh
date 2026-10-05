#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${1:-}" ]; then
  echo "No action argument is supplied eg ./make.sh deploy"
  exit 1
fi

action="$1"
shift

case "$action" in
  setup_ansible)
    uv run --project "$script_dir" startup ansible setup_ansible --working-directory "$script_dir" "$@"
    ;;
  setup)
    uv run --project "$script_dir" startup ansible setup --working-directory "$script_dir" "$@"
    ;;
  deploy)
    uv run --project "$script_dir" startup ansible deploy --working-directory "$script_dir" "$@"
    ;;
  infrastructure)
    uv run --project "$script_dir" startup ansible infrastructure --working-directory "$script_dir" "$@"
    ;;
  update_vms)
    uv run --project "$script_dir" startup ansible update-vms --working-directory "$script_dir" "$@"
    ;;
  k3s_upgrade)
    uv run --project "$script_dir" startup ansible k3s-upgrade --working-directory "$script_dir" "$@"
    ;;
  kubeconfig)
    uv run --project "$script_dir" startup ansible kubeconfig --working-directory "$script_dir" "$@"
    ;;
  backup)
    uv run --project "$script_dir" startup ansible backup --working-directory "$script_dir" "$@"
    ;;
  restore)
    uv run --project "$script_dir" startup ansible restore --working-directory "$script_dir" "$@"
    ;;
  sync)
    uv run --project "$script_dir" startup sync "$@"
    ;;
  secrets_update)
    uv run --project "$script_dir" startup secrets update -r "$script_dir" "$@"
    ;;
  rotate_vault_password)
    uv run --project "$script_dir" startup secrets rotate-password -r "$script_dir" "$@"
    ;;
  list_vaults)
    uv run --project "$script_dir" startup secrets list-vaults -r "$script_dir" "$@"
    ;;
  *)
    echo "Unknown action: $action"
    exit 1
    ;;
esac
