#!/usr/bin/env bash
# GIVEN a real template, WHEN Copier renders a standalone project,
# THEN its instructions load, every local link resolves and every ADR is listed.
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

    # GIVEN a rendered draft policy, WHEN the owner customizes it and Copier runs again,
    # THEN the owner's public configuration survives overwrite/update semantics.
    import json
    policy_path = project / "backend/project/site-policy.json"
    policy = json.loads(policy_path.read_text())
    assert policy["reviewed"] is False and policy["analytics"] == "off"
    policy["operatorName"] = "Example Operator"
    policy_path.write_text(json.dumps(policy))
    product_path = project / "docs/product.md"
    assert "# instructions-check product" in product_path.read_text()
    product_path.write_text(product_path.read_text().replace(
        "Describe the product in two or three sentences, from the user's side.", "Friends draw a game."))
    copier.run_copy(str(source), str(project), defaults=True, quiet=True, overwrite=True,
                    data={"project_name": "instructions-check",
                          "base_domain": "example.com", "github_username": "example"})
    assert json.loads(policy_path.read_text())["operatorName"] == "Example Operator"
    assert "Friends draw a game." in product_path.read_text()
    assert "docs/product.md" in (project / "AGENTS.md").read_text()
    assert (project / "docs/privacy.md").is_file()

    instructions = (project / "AGENTS.md").read_text()
    assert instructions.strip(), "AGENTS.md must contain the project instructions"
    assert not (project / "CLAUDE.md").exists(), "Generated projects use AGENTS.md"

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
    assert exported_adrs <= linked_adrs, "Every exported ADR needs a resolving link"
    # The index section, not any link in AGENTS.md, makes an ADR discoverable.
    index = re.search(r"^## Architecture decisions$(.*?)(?=^## |\Z)", instructions, re.MULTILINE | re.DOTALL)
    assert index, "AGENTS.md needs an '## Architecture decisions' section"
    indexed = {(project / target).resolve() for target in re.findall(r"\]\((docs/architecture/[^)#]+)", index.group(1))}
    assert exported_adrs == indexed, "Every exported ADR needs an entry under '## Architecture decisions'"
    # Template ADRs stay below 0100 so generated projects can number their own from 0100.
    assert all(int(path.name[:4]) < 100 for path in exported_adrs), "Template ADRs use 0001-0099"
    # The generated project carries the ADR check that guards later template updates.
    import subprocess
    subprocess.run([sys.executable, "tests/test_agent_links_integration.py"], cwd=project, check=True)
    test_adrs = [path for path in exported_adrs if path.name.endswith("test-strategy.md")]
    assert len(test_adrs) == 1
    assert "docs/testing-policy.md" in instructions
    assert (project / "docs/testing-policy.md").is_file()

    if (project / "backend").exists():
        assert project / "docs/architecture/0006-business-logic-in-services.md" in linked_adrs
        assert (project / "backend/AGENTS.md").is_file()

    print(f"Real Copier render: instructions load, links resolve, {len(exported_adrs)} ADRs listed")
CHECK
