# Integration and E2E tests with GIVEN / WHEN / THEN

**Status**: Accepted

## Context

A feature works when its real parts work together and a user can complete the
flow. Tests should describe that behaviour clearly and stay useful when the
implementation is refactored.

## Decision

**Integration tests are the default; changed user flows require E2E tests.**
Unit tests are reserved for complex algorithms and supplement these tests.
Every behaviour
change includes an integration test. Changed user flows also include browser
E2E; a bug fix begins with a scenario that reproduces the bug.

Integration tests exercise a public application interface: an HTTP route,
Django view, management command or service use case with real PostgreSQL and
its actual collaborators. Testing a helper in isolation is not an integration
test, even if the helper is public or the test has GIVEN / WHEN / THEN comments.
Browser E2E drives the running application through its actual UI and services.

Write each scenario with explicit **GIVEN / WHEN / THEN**:

- **GIVEN:** arrange only the relevant state through factories or real write
  endpoints. Keep scenario-specific values visible in the test.
- **WHEN:** perform one business action. Filling and submitting one form can
  be several browser steps but is one action; testing logout is another scenario.
- **THEN:** assert observable results: the response or rendered page, persisted
  data and relevant side effects. Do not assert implementation call sequences.

Each test starts with empty, isolated data and runs independently. Use a
separate E2E database and server; never seed or flush development or production
resources. An empty state does not require creating a new database per test.

Do not mock our own code or stub browser fetch calls. For external dependencies,
prefer a small local stand-in reached over the real protocol. Only when that is
impossible may the external boundary be replaced; document the reason in the
test. Neither test level permits replacing our own application modules.

Find browser controls by role and visible label. Use a data-testid only when
there is no suitable semantic locator. Success, invalid input and denied access
are separate scenarios; related scenarios may share one focused spec file.

### Limited algorithm exception

Use focused unit tests only for complex algorithms with meaningful edge cases
or invariants, such as pathfinding, ranking or non-trivial parsing. Explain in
the test or change description what makes the algorithm complex and which
cases need isolated coverage. Exercise the real algorithm without mocking our
own code. Routine helpers, views, models and service workflows stay covered
through integration tests.

Algorithm unit tests supplement integration and E2E tests; they never replace
the required application or user-flow scenarios. Do not add unit tests merely
to increase a coverage percentage. Use GIVEN / WHEN / THEN for them too.

## Coverage and completion evidence

A green pipeline proves that its enabled checks passed, not that every feature
has complete E2E coverage. Smoke tests cover only their named scenarios. Record
uncovered user flows and report provider scenarios skipped because credentials
or external environments are unavailable. Keep required E2E checks enabled while
improving CI speed through isolation, caching and independent parallel jobs.
See [Testing policy and completion evidence](../testing-policy.md).

## Consequences

- Tests document behaviour and cover real persistence and service interaction.
- Factories make the starting state explicit; isolated data prevents order dependence.
- Real services take more setup than isolated helper tests.

## Alternatives considered

- **Unit tests as the default:** miss the integration that users rely on.
- **Mocked application modules:** hide the behaviour of real collaborators.
- **UI clicks for all fixture setup:** slow down tests and obscure the action under test.
- **Shared mutable test data:** makes outcomes depend on execution order.
