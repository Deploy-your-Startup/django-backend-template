# Test strategy

**Status**: Accepted

## Context

The application combines business rules, PostgreSQL persistence, an HTTP API,
server-rendered pages and a deployment. Tests must give reliable
feedback without hiding production behaviour behind test doubles or touching
development data.

## Decision

We write integration and end-to-end tests. We do not write standalone unit
tests, and we do not mock.

1. **Backend integration tests** call the real ASGI application over HTTP and
   use a real, empty PostgreSQL database. They cover ordinary backend
   behaviour, including validation, permissions and persistence.
2. **End-to-end tests** use Playwright against the running application, with
   its own database and port. They cover the
   user flows; a user-visible change ships with an E2E test.

**No mocks, including for external services.** When the application talks to
a service that cannot run locally (a payment provider, a mail API, an identity
provider), start a small stand-in service instead, for example a FastAPI app
or a container, that implements the behaviour the application relies on over
the real protocol. The application reaches it through its normal configuration
(a base URL or an endpoint setting), exactly as in production. Patching functions,
stubbing `fetch` or replacing our own modules is not allowed; a test double is
acceptable only where no stand-in service can work, and the test says why.

Each test builds its GIVEN state explicitly through factories or production
endpoints, follows GIVEN / WHEN / THEN, and asserts what a user or API client
observes. Scenario-specific data stays visible in the test rather than hidden
in shared magic values.

E2E tests find elements by role and visible label, as a user does; a
`data-testid` is added only where no such label exists. Each independently
understandable scenario lives in its own focused spec file.

## Consequences

- Tests exercise PostgreSQL, HTTP and the UI with high
  fidelity, so a green suite is meaningful evidence that the feature works.
- Stand-in services are real code that must follow the external contract; they
  live next to the tests that use them and are reused by local development.
- Integration and E2E tests need local services and are slower than isolated
  unit tests.
- Fresh databases per test give deterministic isolation.

## Alternatives considered

- **Unit tests with mocks or SQLite:** faster, but they hide relevant
  production behaviour and break on refactorings that change nothing a user
  can see.
- **Mocking external clients in-process:** quick to write, but it tests our
  assumptions about the client instead of the HTTP exchange the application
  really performs.
