"""GIVEN the real template, WHEN Copier renders, THEN deployment contracts hold."""
from pathlib import Path
import shutil
import sys
import subprocess
import tempfile

import copier
import yaml

root = Path(sys.argv[1])
manifest = yaml.safe_load((root / "startup-template.yml").read_text())
assert manifest["schema"] == 1 and manifest["shared_cluster"] is True

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
                   if job.get("uses", "").startswith("Deploy-your-Startup/deploy/")]
    assert len(shared_jobs) == 1
    subprocess.run([sys.executable, str(root / "tests/deployment_version_check.py"), str(generated)], check=True)
    assert all(job["uses"].endswith("@codex/shared-cluster") for job in shared_jobs)
    assert not any("§§deploy_your_startup.deploy_ref§§" in path.read_text() for path in workflows)
    # GIVEN a real generated backend, WHEN CI calls the shared harness,
    # THEN coverage is required and the portable instructions define its contract.
    backend_job = next(job for workflow in callers for job in workflow.get("jobs", {}).values() if job.get("with", {}).get("service") == "backend")
    # The shared build lives under another owner, so the caller grants what it nests.
    assert backend_job["permissions"] == {"contents": "read", "actions": "read", "pull-requests": "write", "packages": "write", "id-token": "write"}
    assert backend_job["with"]["run_tests"] is True
    assert backend_job["with"]["require_coverage"] is True
    assert backend_job["with"]["coverage_measured_from"] == "Integration"
    assert "coverage/cobertura.xml" in (generated / "docs/testing.md").read_text()
    assert not (generated / "docs/architecture/0007-coverage-report-contract.md").exists()
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
    # GIVEN the rendered backend, WHEN its image is built, THEN it runs the
    # project's Python and uv cannot quietly download a different one.
    python = (generated / "backend/.python-version").read_text().strip()
    dockerfile = (generated / "backend/Dockerfile").read_text()
    assert f"FROM python:{python}-slim AS builder" in dockerfile
    assert "ENV UV_PYTHON_DOWNLOADS=never" in dockerfile
    assert f'requires-python = "~={python}.0"' in (generated / "backend/pyproject.toml").read_text()
    dependency = (generated / "deployment/pyproject.toml").read_text()
    import re
    assert re.search(r'rev = "[0-9a-f]{40}"', dependency)
    # GIVEN the rendered deployment, WHEN its locked CLI starts,
    # THEN the deployment entrypoint loads. CLI behavior is tested in its own repo.
    subprocess.run(["uv", "run", "--locked", "--project", str(generated / "deployment"),
                    "startup", "ansible", "--help"], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["uv", "run", "--locked", "--project", str(generated / "deployment"),
                    "python", "-I", "-c", "import cli.project_version"], check=True)
    # GIVEN the generated deployment's locked CLI, WHEN its safe-access commands
    # are loaded, THEN an older credential-bearing runtime cannot satisfy the contract.
    for command in ("inspect", "rotate-client-ca"):
        subprocess.run(["uv", "run", "--locked", "--project", str(generated / "deployment"),
                        "startup", "cluster", command, "--help"], check=True, stdout=subprocess.DEVNULL)
    print("Real Copier render: pinned CLI, current Postgres and controller copies verified")
