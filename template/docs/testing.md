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
