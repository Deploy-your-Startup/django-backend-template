#!/usr/bin/env bash
# GIVEN a real rendered application with app assets and collectstatic output,
# WHEN git decides what to track,
# THEN app assets are committed and only the collectstatic root is ignored.
# A broad `static/` rule once kept an app's CSS/JS out of the repository, so
# production served unstyled pages while every local test passed.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
project="$(mktemp -d)"
trap 'rm -rf "$project"' EXIT
uv run --no-project --with copier==9.18.2 python - "$root" "$project" <<'PY'
import shutil
import sys
from pathlib import Path
import copier
source = Path(sys.argv[2]) / "source"
shutil.copytree(sys.argv[1], source, ignore=shutil.ignore_patterns(".git", ".venv", "node_modules", "__pycache__"))
copier.run_copy(str(source), str(Path(sys.argv[2]) / "app"), defaults=True, quiet=True,
                data={"project_name": "static-check", "base_domain": "example.com", "github_username": "example"})
PY
cd "$project/app"
git init -q
mkdir -p backend/api/static/api backend/static/admin
echo "body {}" > backend/api/static/api/app.css
echo "collected" > backend/static/admin/base.css
# THEN the app asset is tracked ...
if git check-ignore -q backend/api/static/api/app.css; then
  echo "App static assets are ignored by git: $(git check-ignore -v backend/api/static/api/app.css)" >&2
  exit 1
fi
# ... and the collectstatic output stays out of the repository.
git check-ignore -q backend/static/admin/base.css
