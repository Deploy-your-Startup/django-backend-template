#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
    lint)
        bash -n template/backend/make.sh template/deployment/make.sh template/e2e_tests/make.sh
        cd template/backend
        ./make.sh lint
        ;;
    format)
        cd template/backend
        ./make.sh format
        ;;
    *) echo 'Usage: ./make.sh {format|lint}' >&2; exit 2 ;;
esac
