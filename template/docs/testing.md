# Test coverage

Run `backend/make.sh coverage` for integration coverage and
`STARTUP_COVERAGE=true e2e_tests/make.sh test_e2e` for browser coverage. The backend combines available
integration and E2E data through `backend/make.sh coverage_report`. Delete the service's
`coverage/` directory before a fresh measurement.

Normal local tests and browser runs do not measure coverage.

Each measured service writes `coverage/cobertura.xml` with service-relative paths.
The service owns the measurement tools; shared pipelines consume only Cobertura.
Generated backend workflows enable `require_coverage: true`: successful tests
without a valid report fail CI. There is no percentage threshold.

Build pipelines publish integration coverage in the job summary, a sticky PR
comment and a `coverage-backend` artifact. PR comment permissions may be unavailable
for forks; the summary and artifact remain available.

Combined integration and browser coverage is currently available from local E2E
runs. The shared build pipeline reports integration coverage only.


## Container CI gate

The shared parallel workflow builds production images alongside integration and
browser checks. Publication requires every enabled check to succeed. Browser
tools belong in `e2e_tests/Dockerfile`, separate from the production Dockerfile.
Each E2E shard owns a disposable Compose database and a single browser worker.
Playwright distributes individual scenarios across shards. Set `e2e_shards` in
the caller workflow to match the size of the suite; more shards also start more
runners. No deployment duration is guaranteed.

Integration tests use two pytest workers with independent databases. Set
`TEST_WORKERS=0` for serial debugging. Browser reports remain separate from
integration coverage in CI; percentages are never averaged.

Existing projects first need the compatible shared parallel workflow in their
owner deployment repository via `startup sync`. Application files are updated
separately with `startup template update`; preview both operations first.
