# Startup project instructions

The backend combines Django and FastAPI in one ASGI application. Use the service
runtime selected by `.python-version` and global uv; Node is selected by mise.

```bash
mise run backend:dev
mise run backend:lint
mise run backend:test
mise run e2e:test
```

Each service owns its `make.sh` contract: `format` changes files, `lint` only
checks them. Run the versions pinned in pyproject.toml through uv run. CI must
only lint, never format. Do not add pre-commit hooks.

Local Postgres is started by Compose only when DATABASE_URL is absent.
Configure LOCAL_DB_NAME and POSTGRES_PORT for concurrent stacks.

Always use startup CLI for deployment, Ansible and Vault operations. Never print
or persist decrypted secrets. Ask before destructive restore or secret rotation.

## Testing

Follow [Testing policy and completion evidence](docs/testing-policy.md) and
[ADR 0001](docs/architecture/0001-test-strategy.md). Exercise the real
application, PostgreSQL and service boundaries; changed user flows get browser
E2E.

- **GIVEN:** arrange the relevant state explicitly with factories or real write
  endpoints. Name the scenario-specific values in the test.
- **WHEN:** perform one business action through the application's public interface.
- **THEN:** assert the result a user or API client observes, including persistence
  and side effects where relevant. Do not assert private helper calls.
- Each test starts with an empty, isolated database and must pass independently.
  Never seed or flush development or production data.
- Find browser elements by role and visible label. Test success, validation and
  permission failures as separate scenarios.

## Security before public sharing

- Test anonymous and other-account access to private data and every write; keep
  ownership checks server-side and CSRF protection on cookie-authenticated writes.
- Bound uploads (bytes, count, pixels), stored data and paid API usage per user;
  rate-limit login and registration where the app handles credentials.
- Verify production HTTPS, Secure/HttpOnly session cookies and HSTS through the
  actual ingress; trust forwarded headers only from the trusted proxy.
- Before declaring a launch complete, verify live CSS/JS and a core user flow;
  HTTP 200 alone is insufficient.
- Public links expose only explicitly approved data, never login identities,
  secrets or source uploads. `noindex` is not access control. Verify live behaviour
  separately from local tests before calling a release safe to share.

Django session login needs production `SESSION_COOKIE_SECURE` and
`CSRF_COOKIE_SECURE`, plus login throttling; framework defaults are insufficient.

## Business logic

Keep business logic in **`services.py` per Django app or business area** (ADR 0006).
Routes, views and commands adapt input, call a service and return a response.
Services own business rules, queries, transactions and side effects; models
own data and row invariants. Avoid a single project-wide service collection.

## Working conventions

- KEEP IT SIMPLE: avoid over-engineering, premature abstractions and
  unnecessary configuration. Prefer plain, readable code over clever code.
- Never push directly to `main`; use a feature branch and a pull request.
  Branch names and commit format: [`.github/git-commit-instructions.md`](.github/git-commit-instructions.md).
- **Pull request titles and descriptions are always in English**, even when the
  conversation was in another language.
- Before finishing, run lint and tests for every service you changed, and E2E
  for user-visible changes.

## Code style

- Prefer descriptive names over abbreviations, also for loop variables.
- Boolean functions and variables start with `is`, `has`, `can` or `should`.
- Prefer explicit code and setup over implicit conventions. In tests, keep
  scenario-specific data visible in the test instead of hiding it in shared
  magic values.
- Declare parameter and return types at public interfaces (ADR 0002). Private
  Python helpers and internal TypeScript helpers may infer their return types.
  Keep callback inference; test code is exempt.
- Comment the why, not the what; document a rule once at its interface
  (ADR 0003).

## Architecture decisions

Record decisions that shape the project as numbered ADRs in
`docs/architecture/` and list them here with when to load them (ADR 0003).
Numbers 0001-0099 belong to the template and arrive through template updates;
number project ADRs from 0100 upward. Never reuse or renumber a template ADR.

- [ADR 0001](docs/architecture/0001-test-strategy.md) — load when writing integration or E2E scenarios; includes GIVEN / WHEN / THEN and isolation.
- [ADR 0002](docs/architecture/0002-explicit-types.md) — load when adding or changing production functions.
- [ADR 0003](docs/architecture/0003-documentation-at-interfaces.md) — load when adding comments, documentation or an ADR.
- [ADR 0004](docs/architecture/0004-application-structure.md) — load for topology, stack, authentication or database choices.
- [ADR 0005](docs/architecture/0005-service-command-contract.md) — load when adding a service or changing make.sh, mise tasks or CI.
- [ADR 0006](docs/architecture/0006-business-logic-in-services.md) — load when adding business rules, queries, transactions or an entry point.
- [ADR 0008](docs/architecture/0008-local-consent.md) — load when adding analytics, cookies, external services or personal-data processing.
- [ADR 0009](docs/architecture/0009-monorepo.md) — load when adding a service, moving code between services or splitting the repository.

## Template updates (Copier)

From the repo root with a clean working tree:

```bash
startup template update --version <release-tag> --dry-run
startup template update --version <release-tag>
```

Review the diff, resolve conflicts, run affected lint/tests/E2E, then commit
including `.copier-answers.yml`. A separate branch is optional; Copier does
not commit, push or deploy.
Do not edit Copier answers manually. Existing deployment/group_vars files are
preserved. `startup sync` handles shared deployment roles/workflows separately.

## Coverage contract

- `./make.sh coverage` runs measured tests and writes `<service>/coverage/cobertura.xml` (Cobertura XML, paths relative to the service).
- Local `./make.sh test` and browser runs do not measure coverage by default. Generated backend pipelines set `require_coverage: true`; missing or invalid reports fail CI. No percentage threshold is enforced.
- Measure integration and E2E tests, never add unit tests for coverage.
- See [Testing](docs/testing.md) for commands and pipeline reports.

## Legal information and optional tracking

Read [Privacy](docs/privacy.md) and [ADR 0008](docs/architecture/0008-local-consent.md)
when adding analytics, cookies, external services or personal-data processing.
Use the existing locally bundled consent integration; do not add a hosted CMP
account or bypass consent by inserting tracker tags. Update project disclosures
and consent revision when purposes change. Never invent operator details or mark
unreviewed placeholders as complete. Test no tracking before permission, after
rejection and after withdrawal, plus public legal links.

Before a public launch, collect the missing publication-approved operator
details together and review the disclosures; until then the startup is not
ready for launch and optional analytics stay off.
