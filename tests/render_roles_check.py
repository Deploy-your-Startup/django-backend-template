"""GIVEN the real template, WHEN Copier renders, THEN deployment contracts hold."""
from pathlib import Path
import shutil
import sys
import tempfile

import copier
import yaml

root = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as temporary:
    source = Path(temporary) / "source"
    generated = Path(temporary) / "generated"
    shutil.copytree(root, source, ignore=shutil.ignore_patterns(
        ".git", ".venv", "node_modules", "__pycache__", ".pytest_cache", "dist", ".ruff_cache"))
    copier.run_copy(str(source), str(generated), defaults=True, unsafe=True, quiet=True,
                    data={"project_name": "role-check", "base_domain": "example.com",
                          "github_username": "example"})
    playbook = yaml.safe_load((generated / "deployment/playbook.yml").read_text())
    tasks = [task for play in playbook for task in play.get("tasks", [])]
    copies = [task for task in tasks if task.get("name", "").startswith("copy ")]
    assert copies
    for task in copies:
        assert task["delegate_to"] == "localhost"
        assert task["become"] is False
        assert task["vars"]["ansible_python_interpreter"] == "{{ ansible_playbook_python }}"
    preparation = [task for task in tasks if task.get("import_role", {}).get("name") == "kubernetes-client"]
    assert preparation and preparation[0]["tags"] == "always"
    variables = yaml.load((generated / "deployment/group_vars/production.yml").read_text(), Loader=yaml.BaseLoader)
    assert variables["postgres_version"] == "18.6"
    dependency = (generated / "deployment/pyproject.toml").read_text()
    assert 'rev = "c5cda4bbdaa64f65c8adab0f5fc5dd1717439b66"' in dependency
    print("Real Copier render: pinned CLI, current Postgres and controller copies verified")
