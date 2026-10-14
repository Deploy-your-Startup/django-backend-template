#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# GIVEN the locked deployment runtime, WHEN its public kubeconfig command is
# inspected, THEN automatic SSH access and the explicit direct opt-out exist.
uv run --locked --project "$root" startup ansible kubeconfig --help > "$tmp/help"
grep -q -- '--direct' "$tmp/help"
grep -q -- '--ssh-identity' "$tmp/help"

# GIVEN an invalid SSH destination, WHEN the real installed CLI connects,
# THEN it rejects the input without creating or overwriting kubeconfig.
if uv run --locked --project "$root" startup cluster connect \
  --context sample --host=-invalid --kubeconfig "$tmp/config" > "$tmp/error" 2>&1; then
  echo 'FAIL: invalid SSH destination accepted' >&2
  exit 1
fi
grep -q 'Invalid SSH host' "$tmp/error"
test ! -e "$tmp/config"

# GIVEN an attached startup, WHEN a firewall change is attempted,
# THEN the owner guard rejects it before credentials or network access.
mkdir "$tmp/attached"
printf 'managed: false\nowner: example/cluster-owner\n' > "$tmp/attached/cluster.yml"
if uv run --locked --project "$root" startup ansible firewall \
  --working-directory "$tmp/attached" --execute > "$tmp/guard" 2>&1; then
  echo 'FAIL: attached startup changed a shared firewall' >&2
  exit 1
fi
grep -q 'run it from example/cluster-owner' "$tmp/guard"
echo 'PASS: locked SSH access runtime and firewall ownership guard'
