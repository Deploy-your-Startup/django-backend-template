#!/usr/bin/env bash
# GIVEN a real rendered application with app assets and collectstatic output,
# WHEN the developer commits it and CI checks it out,
# THEN production serves CSS/JS and collectstatic output stays untracked.
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
git -c init.defaultBranch=main init -q
# GIVEN source assets in an installed Django app and a generated output file.
mkdir -p backend/api/static/api backend/static/admin
printf 'body { color: blue; }\n' > backend/api/static/api/app.css
printf 'console.log("static-check");\n' > backend/api/static/api/app.js
printf 'collected\n' > backend/static/admin/base.css

# WHEN a developer commits the generated project and CI checks it out afresh.
git -c core.excludesFile=/dev/null add .
git -c user.name="Static asset integration test" -c user.email="test@example.com" \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm "Create generated project"
git clone -q "$project/app" "$project/checkout"
cd "$project/checkout"

# THEN both assets survive the checkout, while collectstatic output does not.
cmp ../app/backend/api/static/api/app.css backend/api/static/api/app.css
cmp ../app/backend/api/static/api/app.js backend/api/static/api/app.js
test ! -e backend/static/admin/base.css
git -c core.excludesFile=/dev/null check-ignore -q backend/static/admin/base.css

# Production serving must work from the committed sources, not Django's
# development-only static finder. Static requests do not use the database.
cd backend
export PRODUCTION=true SECRET_KEY=static-integration-test-only
export DATABASE_URL="${DATABASE_URL:-postgres://test:test@127.0.0.1:1/static_check}"
uv run --locked python manage.py collectstatic --noinput --verbosity 0
mkdir -p media
uv run --locked python - <<'PYTEST'
from pathlib import Path
from fastapi.testclient import TestClient
from project.asgi import app

with TestClient(app, base_url="https://example.com") as client:
    for filename, content_type in [("app.css", "text/css"), ("app.js", "javascript")]:
        response = client.get(f"/static/api/{filename}")
        assert response.status_code == 200, (filename, response.status_code)
        assert content_type in response.headers["content-type"], response.headers
        assert response.content == Path(f"api/static/api/{filename}").read_bytes()
PYTEST
