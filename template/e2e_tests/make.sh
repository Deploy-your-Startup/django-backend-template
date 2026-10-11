#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
    setup_local) npm ci; npx playwright install chromium ;;
    # The backend server runs under coverage.py; its data is combined with the
    # integration tests into backend/coverage/cobertura.xml (ADR 0007).
    test_e2e) shift; npm test -- "$@"; ../backend/make.sh coverage ;;
    format) npm run format ;;
    lint) npm run format:check ;;
    *) echo 'Usage: ./make.sh {setup_local|test_e2e|format|lint}' >&2; exit 2 ;;
esac
