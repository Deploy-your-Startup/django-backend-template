#!/usr/bin/env bash
# GIVEN a generated project, WHEN its real linters check public and private
# functions, THEN public Python signatures stay enforced and helpers can infer.
set -euo pipefail
project="$(cd "${1:?Pass the generated project directory}" && pwd)"
fixtures="$(mktemp -d)"
trap 'rm -rf "$fixtures"' EXIT
cat > "$fixtures/helpers.py" <<'PYTHON'
def _internal_value(value: int):
    return value + 1


def public_value(value: int) -> int:
    return _internal_value(value)
PYTHON
uv run --project "$project/backend" ruff check --config "$project/backend/pyproject.toml" "$fixtures/helpers.py"
cat > "$fixtures/public.py" <<'PYTHON'
def public_value(value: int):
    return value + 1
PYTHON
if uv run --project "$project/backend" ruff check --config "$project/backend/pyproject.toml" "$fixtures/public.py" > "$fixtures/diagnostic" 2>&1; then
    echo 'A public Python function without a return type unexpectedly passed' >&2
    exit 1
fi
grep 'ANN201' "$fixtures/diagnostic"
if [ -d "$project/frontend" ]; then
    test -x "$project/frontend/node_modules/.bin/oxlint"
    cat > "$fixtures/helpers.ts" <<'TYPESCRIPT'
function internalValue(value: number) { return value + 1; }
export function publicValue(value: number): number { return internalValue(value); }
TYPESCRIPT
    "$project/frontend/node_modules/.bin/oxlint" --deny-warnings --config "$project/frontend/.oxlintrc.json" "$fixtures/helpers.ts"
fi
