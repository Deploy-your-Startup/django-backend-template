# Startup project instructions

Django + FastAPI in one ASGI application with server-rendered pages and HTMX
(ADR 0004). Each service has its own `AGENTS.md` with local rules.

```bash
mise run dev
mise run backend:lint
mise run backend:test
mise run e2e:test
```

Every service is driven through its `make.sh`; `format` writes, `lint` only
checks, CI only lints (ADR 0005).
Local Postgres is started by Compose only when DATABASE_URL is absent.

Use the startup CLI for deployment, Ansible and Vault. Never print or persist
decrypted secrets. Ask before destructive restores or secret rotation.

## Where the rules live

| Topic | Source |
|---|---|
| Tests and completion claims | [Testing policy](docs/testing-policy.md), [ADR 0001](docs/architecture/0001-test-strategy.md), [coverage](docs/testing.md) |
| Security before public sharing | [Security checklist](docs/security.md) |
| Legal pages, consent, analytics | [Privacy](docs/privacy.md), [ADR 0008](docs/architecture/0008-local-consent.md) |
| Template updates | [Operations](docs/operations.md) |
| Branches and commits | [Commit conventions](.github/git-commit-instructions.md) |

## Working conventions

- Keep it simple: no premature abstractions or unnecessary configuration.
- Business logic lives in `services.py` per Django app (ADR 0006); declare types
  at public interfaces (ADR 0002); comment the why, once, at the interface (ADR 0003).
- Use descriptive names; booleans start with `is`, `has`, `can` or `should`.
- Never push directly to `main`; open a pull request with an English title and
  description.
- Before completing code changes, run lint and all tests locally: integration,
  existing unit and browser E2E. Record failures and skips; CI does not replace this.
- Before committing, check `git status --short --ignored` for files you created:
  a passing local run proves nothing if CI checks out without an ignored file.

## Architecture decisions

Load an ADR when its topic comes up. Numbers 0001-0099 belong to the template
and arrive through template updates; number project ADRs from 0100 upward.

- [ADR 0001](docs/architecture/0001-test-strategy.md) — writing integration or E2E scenarios.
- [ADR 0002](docs/architecture/0002-explicit-types.md) — adding or changing production functions.
- [ADR 0003](docs/architecture/0003-documentation-at-interfaces.md) — adding comments, documentation or an ADR.
- [ADR 0004](docs/architecture/0004-application-structure.md) — topology, stack, authentication or database choices.
- [ADR 0005](docs/architecture/0005-service-command-contract.md) — adding a service or changing make.sh, mise tasks or CI.
- [ADR 0006](docs/architecture/0006-business-logic-in-services.md) — business rules, queries, transactions or entry points.
- [ADR 0008](docs/architecture/0008-local-consent.md) — analytics, cookies, external services or personal data.
- [ADR 0009](docs/architecture/0009-monorepo.md) — adding a service, moving code or splitting the repository.
- [ADR 0010](docs/architecture/0010-tests-as-specification.md) — specifying behaviour, writing a task or adding a requirement.

## Project notes

List project ADRs (0100+) under Architecture decisions above; keep any other
project rule here as a short pointer to its doc.
