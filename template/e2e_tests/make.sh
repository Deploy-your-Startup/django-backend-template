#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
    setup_local) npm ci; npx playwright install chromium ;;
    # With STARTUP_COVERAGE=true the backend runs under coverage.py; its data is combined with the
    # integration tests into backend/coverage/cobertura.xml (see docs/testing.md).
    test_e2e) shift; npm test -- "$@"; if [ "${STARTUP_COVERAGE:-false}" = true ]; then ../backend/make.sh coverage_report; fi ;;
    ci_e2e)
        mkdir -p /reports
        status=0
        "$0" test_e2e --shard="${SHARD_INDEX:-1}/${SHARD_TOTAL:-1}" || status=$?
        cp -R test-results /reports/ 2>/dev/null || true
        cp -R playwright-report /reports/ 2>/dev/null || true
        cp -R ../backend/coverage /reports/ 2>/dev/null || true
        exit "$status"
        ;;
    format) npm run format ;;
    lint) npm run format:check ;;
    *) echo 'Usage: ./make.sh {setup_local|test_e2e|format|lint}' >&2; exit 2 ;;
esac
