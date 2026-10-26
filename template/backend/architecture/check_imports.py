"""Require nonempty configured scopes before running Tach's import analysis."""

import json
import subprocess
import sys
import tomllib
from graphlib import CycleError, TopologicalSorter
from pathlib import Path


def main() -> None:
    root = Path.cwd()
    configuration = tomllib.loads((root / "tach.toml").read_text())
    for module in configuration["modules"]:
        for name in module["paths"]:
            pattern = name.replace(".", "/")
            if not any(root.glob(pattern + ".py")) and not any(
                root.glob(pattern + "/**/*.py")
            ):
                # Tach 0.35 only warns about disappeared modules. Fail the lint
                # gate instead of accepting a stale or accidentally empty scope.
                sys.exit(f"Missing configured module or empty scope: {name}")
    executable = str(Path(sys.executable).with_name("tach"))
    checked = subprocess.run(
        [executable, "check"], check=False, capture_output=True, text=True
    )
    if checked.returncode:
        sys.stderr.write(checked.stdout + checked.stderr)
        sys.exit(checked.returncode)
    # Tach's circular-dependency flag validates declared module dependencies.
    # Check actual source edges too, using Tach's Rust parser and stdlib graphlib.
    graph = json.loads(
        subprocess.run(
            [executable, "map"], check=True, capture_output=True, text=True
        ).stdout
    )
    if not graph:
        sys.exit("Tach returned an empty source dependency graph")
    try:
        TopologicalSorter(graph).prepare()
    except CycleError as error:
        sys.exit("Circular source imports: " + " -> ".join(error.args[1]))
    sys.stdout.write(checked.stdout + checked.stderr)


if __name__ == "__main__":
    main()
