#!/usr/bin/env bash
# GIVEN a real rendered application, WHEN the service verbs run,
# THEN local tests remain unmeasured and explicit coverage produces Cobertura.
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
                data={"project_name": "coverage-check", "base_domain": "example.com", "github_username": "example"})
PY
cd "$project/app/backend"
export DATABASE_URL=sqlite:///:memory:
./make.sh test api/tests.py
# THEN the default run has no measurement overhead or output.
test ! -e coverage/cobertura.xml
test ! -e coverage/integration.coverage
./make.sh coverage api/tests.py
# THEN the explicit run records real API requests in a service-relative report.
uv run python - <<'PY'
from pathlib import Path
from xml.etree import ElementTree
root = ElementTree.parse("coverage/cobertura.xml").getroot()
assert root.tag == "coverage"
assert int(root.get("lines-covered")) > 0
assert any(c.get("filename") == "api/routes.py" for c in root.iter("class"))
assert Path("coverage/integration.coverage").is_file()
PY
