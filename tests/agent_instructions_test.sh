#!/usr/bin/env bash
# GIVEN a real template, WHEN Copier renders a standalone project,
# THEN its core development rules and every linked ADR are available.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
uv run --no-project --with copier==9.18.2 python - "$root" <<'CHECK'
from pathlib import Path
import re
import shutil
import sys
import tempfile

import copier

root = Path(sys.argv[1])
contributors = (root / "AGENTS.md").read_text()
assert "Every change ships with integration tests, plus E2E tests" in contributors
assert "Unit tests are reserved for complex algorithms" in contributors
assert "Never write unit tests" not in contributors
readme = (root / "README.md").read_text()
assert "startup doctor" in readme
assert "gh auth login" in readme
assert re.search(r"--template-version v\d+\.\d+\.\d+", readme)
assert "uv tool install deploy-your-startup-cli" not in readme
with tempfile.TemporaryDirectory() as temporary:
    source = Path(temporary).resolve() / "source"
    project = Path(temporary).resolve() / "project"
    # Copy the working tree so this checks unpublished changes too, without
    # relying on Git HEAD or a maintainer's project checkout.
    shutil.copytree(root, source, ignore=shutil.ignore_patterns(
        ".git", ".venv", "node_modules", "__pycache__", ".pytest_cache",
        ".ruff_cache", "dist", "test-results", "playwright-report"))
    copier.run_copy(str(source), str(project), defaults=True, quiet=True,
                    data={"project_name": "instructions-check",
                          "base_domain": "example.com", "github_username": "example"})

    instructions = (project / "AGENTS.md").read_text()
    assert "@AGENTS.md" in (project / "CLAUDE.md").read_text().splitlines()
    assert "Unit tests are reserved for complex algorithms" in instructions
    assert "Never write unit tests" not in instructions
    assert "GIVEN / WHEN / THEN" in instructions
    assert "## Testing" in instructions

    # THEN the security obligations survive the real Copier render too.
    assert "## Security before public sharing" in instructions
    for rule in ["other-account", "CSRF", "per user", "rate-limit login",
                 "Secure/HttpOnly", "HSTS", "noindex", "live behaviour"]:
        assert rule in instructions, f"Missing security instruction: {rule}"
    assert "SESSION_COOKIE_SECURE" in instructions
    assert "CSRF_COOKIE_SECURE" in instructions

    # All local links resolve inside the generated project, not the source repo.
    linked_adrs = set()
    for document in [project / "AGENTS.md", *sorted((project / "docs/architecture").glob("*.md"))]:
        for target in re.findall(r"(?<!!)\[[^\]]+\]\(([^)]+)\)", document.read_text()):
            if "://" in target or target.startswith("#"):
                continue
            linked = (document.parent / target.split("#")[0]).resolve()
            assert linked.is_relative_to(project), target
            assert linked.is_file(), f"{document.name}: missing {target}"
            if linked.parent == project / "docs/architecture":
                linked_adrs.add(linked)
    exported_adrs = set((project / "docs/architecture").glob("*.md"))
    assert exported_adrs == linked_adrs, "Every exported ADR needs an AGENTS.md entry"
    test_adrs = [path for path in exported_adrs if path.name.endswith("test-strategy.md")]
    assert len(test_adrs) == 1
    strategy = test_adrs[0].read_text()
    assert "Unit tests are reserved for complex algorithms" in strategy
    assert "Never write unit tests" not in strategy
    for phase in ["GIVEN", "WHEN", "THEN"]:
        assert f"**{phase}:**" in strategy
    assert "one business action" in strategy
    assert "## Consequences" in strategy
    policy = (project / "docs/testing-policy.md").read_text()
    assert "docs/testing-policy.md" in instructions
    assert "not a pass" in policy
    assert "Record uncovered flows" in policy
    assert "Every enabled shard must succeed" in policy
    assert "../testing-policy.md" in strategy
    assert "not that every feature" in strategy
    assert "they never replace" in strategy
    assert "coverage percentage" in strategy

    if (project / "backend").exists():
        business = project / "docs/architecture/0006-business-logic-in-services.md"
        assert business in linked_adrs
        assert "services.py" in instructions
        backend_instructions = (project / "backend/AGENTS.md").read_text()
        assert "services.py" in backend_instructions
        assert "Unit tests are reserved for complex algorithms" in backend_instructions
        assert "never unit tests" not in backend_instructions
        assert "per Django app or business area" in business.read_text()
        assert "Do not mock services" in business.read_text()
        assert "limited exception in ADR 0001" in business.read_text()

    print(f"Real Copier render: core instructions and {len(exported_adrs)} linked ADRs verified")
CHECK
