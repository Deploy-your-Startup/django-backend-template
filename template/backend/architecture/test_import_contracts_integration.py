"""Run the lint analyzer on disposable copies of the shipped application."""

import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]


@pytest.fixture
def backend_copy(tmp_path):
    configuration = BACKEND / "tach.toml"
    shutil.copy(configuration, tmp_path / configuration.name)
    shutil.copy(BACKEND / "pyproject.toml", tmp_path)
    (tmp_path / "architecture").mkdir()
    shutil.copy(BACKEND / "architecture/check_imports.py", tmp_path / "architecture")
    modules = tomllib.loads(configuration.read_text())["modules"]
    packages = {path.split(".")[0] for module in modules for path in module["paths"]}
    for package in packages:
        shutil.copytree(
            BACKEND / package,
            tmp_path / package,
            ignore=shutil.ignore_patterns("__pycache__"),
        )
    return tmp_path


def lint_imports(directory):
    return subprocess.run(
        [sys.executable, "architecture/check_imports.py"],
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
    assert "All modules validated" in result.stdout + result.stderr


def test_production_import_of_test_helper_fails(backend_copy):
    # GIVEN a production route importing a real test helper
    path = backend_copy / "api/routes.py"
    path.write_text(path.read_text() + "\nfrom project import testing\n")
    # WHEN the lint analyzer checks the dependency graph
    result = lint_imports(backend_copy)
    # THEN the production-to-test contract fails
    assert result.returncode != 0
    assert "project.testing" in result.stdout + result.stderr


def test_import_cycle_fails(backend_copy):
    # GIVEN two application modules importing each other
    path = backend_copy / "api/routes.py"
    path.write_text(path.read_text() + "\nfrom api import cycle_probe\n")
    (backend_copy / "api/cycle_probe.py").write_text("from api import routes\n")
    # WHEN the lint analyzer checks the actual source graph
    result = lint_imports(backend_copy)
    # THEN the cycle is rejected
    assert result.returncode != 0
    assert "circular" in (result.stdout + result.stderr).lower()


def test_missing_declared_source_fails(backend_copy):
    # GIVEN a configured production source disappearing
    (backend_copy / "api/routes.py").unlink()
    # WHEN the lint analyzer loads its contracts
    result = lint_imports(backend_copy)
    # THEN the scope cannot silently become an empty passing check
    assert result.returncode != 0
    assert "routes" in result.stdout + result.stderr
