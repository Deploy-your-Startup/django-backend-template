#!/usr/bin/env bash
# GIVEN a real Copier render, WHEN both Compose shards run,
# THEN the app works with isolated databases and coverage survives cleanup.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
project="$(mktemp -d)"
trap 'rm -rf "$project"' EXIT
uv run --no-project --with copier==9.18.2 python - "$root" "$project" <<'PYTHON'
import shutil, sys
from pathlib import Path
import copier
source = Path(sys.argv[2]) / "source"
shutil.copytree(sys.argv[1], source, ignore=shutil.ignore_patterns(".git", ".venv", "node_modules", "__pycache__"))
copier.run_copy(str(source), str(Path(sys.argv[2]) / "app"), defaults=True, quiet=True,
    data={"project_name": "container-check", "base_domain": "example.com", "github_username": "example"})
PYTHON
cd "$project/app"
export E2E_IMAGE="startup-template-e2e:check-$$"
docker build -f e2e_tests/Dockerfile -t "$E2E_IMAGE" .
run_shard() (
    export SHARD_INDEX="$1" SHARD_TOTAL=2
    export COMPOSE_PROJECT_NAME="template-e2e-$$-$1"
    compose=(docker compose -f e2e_tests/compose.yml)
    trap '"${compose[@]}" down --volumes --remove-orphans' EXIT
    "${compose[@]}" up --no-build --abort-on-container-exit --exit-code-from test
    mkdir -p "$project/reports-$1"
    "${compose[@]}" cp test:/reports/. "$project/reports-$1/"
    test -s "$project/reports-$1/coverage/cobertura.xml"
)
run_shard 1 & first=$!
run_shard 2 & second=$!
status=0
wait "$first" || status=1
wait "$second" || status=1
exit "$status"
