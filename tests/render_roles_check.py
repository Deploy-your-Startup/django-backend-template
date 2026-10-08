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
                          "github_username": "example", "deploy_ref": "codex/shared-cluster"})
    workflows = list((generated / ".github/workflows").glob("*.yml"))
    callers = [yaml.safe_load(path.read_text()) for path in workflows]
    shared_jobs = [job for workflow in callers for job in workflow.get("jobs", {}).values()
                   if "uses" in job and "/deploy-your-startup/" in job["uses"]]
    assert shared_jobs
    assert all(job["uses"].endswith("@codex/shared-cluster") for job in shared_jobs)
    assert not any("§§deploy_your_startup.deploy_ref§§" in path.read_text() for path in workflows)
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
    # GIVEN a rendered project, WHEN deploying only backend, THEN its database
    # and registry/TLS prerequisites are selected before the application.
    backend = next(i for i, task in enumerate(tasks) if task.get("name") == "deploy backend")
    for role in ("docker-secrets", "cert-manager", "postgres"):
        index = next(i for i, task in enumerate(tasks) if task.get("import_role", {}).get("name") == role)
        assert index < backend
        assert "backend" in tasks[index]["tags"].split(",")
    variables = yaml.load((generated / "deployment/group_vars/production.yml").read_text(), Loader=yaml.BaseLoader)
    assert variables["postgres_version"] == "18.6"
    dependency = (generated / "deployment/pyproject.toml").read_text()
    assert 'rev = "3b92a4c8f8b685a4371e7d1d6b8b0bbc1cd38c08"' in dependency
    print("Real Copier render: pinned CLI, current Postgres and controller copies verified")
