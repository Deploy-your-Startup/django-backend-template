#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
    setup_local) npm ci; npx playwright install chromium ;;
    test_e2e) shift; npm test -- "$@" ;;
    format) npm run format ;;
    lint) npm run format:check ;;
    *) echo 'Usage: ./make.sh {setup_local|test_e2e|format|lint}' >&2; exit 2 ;;
esac
