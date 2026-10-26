"""Run the lint analyzer on disposable copies of the shipped application."""

import shutil
import subprocess
import sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]


@pytest.fixture
def backend_copy(tmp_path):
    for name in ("api", "project", "docker_database_url"):
        shutil.copytree(
            BACKEND / name,
            tmp_path / name,
            ignore=shutil.ignore_patterns("__pycache__"),
        )
    shutil.copy(BACKEND / "pyproject.toml", tmp_path)
    return tmp_path


def lint_imports(directory):
    return subprocess.run(
        [str(Path(sys.executable).with_name("lint-imports")), "--no-cache"],
        cwd=directory,
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )


def test_shipped_application_passes(backend_copy):
    # GIVEN the actual application sources and committed configuration
    # WHEN the same analyzer as make.sh lint checks them
    result = lint_imports(backend_copy)
    # THEN it passes a populated graph
    assert result.returncode == 0, result.stdout + result.stderr
    assert "0 broken" in result.stdout
    assert "Analyzed 0 files" not in result.stdout


def test_production_import_of_test_helper_fails(backend_copy):
    # GIVEN a production route importing a real test helper
    path = backend_copy / "api/routes.py"
    path.write_text(path.read_text() + "\nfrom project import testing\n")
    # WHEN the lint analyzer checks the dependency graph
    result = lint_imports(backend_copy)
    # THEN the production-to-test contract fails
    assert result.returncode != 0
    assert "Production code does not import test helpers BROKEN" in result.stdout


def test_import_cycle_fails(backend_copy):
    # GIVEN two application modules importing each other
    path = backend_copy / "api/routes.py"
    path.write_text(path.read_text() + "\nfrom api import cycle_probe\n")
    (backend_copy / "api/cycle_probe.py").write_text("from api import routes\n")
    # WHEN the lint analyzer checks the actual source graph
    result = lint_imports(backend_copy)
    # THEN the cycle is rejected
    assert result.returncode != 0
    assert "Application packages have no sibling import cycles BROKEN" in result.stdout


def test_missing_declared_source_fails(backend_copy):
    # GIVEN a configured production source disappearing
    (backend_copy / "api/routes.py").unlink()
    # WHEN the lint analyzer loads its contracts
    result = lint_imports(backend_copy)
    # THEN the scope cannot silently become an empty passing check
    assert result.returncode != 0
    assert "routes" in result.stdout + result.stderr
