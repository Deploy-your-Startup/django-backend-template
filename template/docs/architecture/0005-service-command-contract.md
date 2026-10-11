# One command contract per service

**Status**: Accepted

## Context

A project grows services in different languages: today a Python backend and
end-to-end tests, tomorrow perhaps a worker or a second frontend. Developers,
coding agents and CI all need to know how to set up, run, lint and test each
one without learning its toolchain first. The shared Deploy Your Startup
pipelines serve many projects at once and must not depend on a project's
languages.

## Decision

Every service directory owns an executable `make.sh`; it is the only way
developers, agents and CI run that service's tools. Application services (the
ones CI builds and tests) provide the same core commands:

| Command | Contract |
|---|---|
| `setup_local` | install the service's dependencies |
| `run_dev` | start it for local development (where it runs on its own) |
| `format` | rewrite files into the project's formatting |
| `lint` | check formatting, lint rules and types; never writes |
| `test` | run the service's tests |

Supporting directories such as `deployment` expose their own commands
(`deploy`, `backup`, ...) through `make.sh` in the same way.

A service adds commands it needs (`generate_client`, `test_e2e`, `deploy`)
without changing the meaning of the shared ones. `mise.toml` exposes them as
`<service>:<command>` tasks for the whole repository. Tool versions are pinned
inside the service, for example in `pyproject.toml` or `package.json`, and run
through the service's own runner.

CI calls only this contract: the shared build workflow builds the service's
Dockerfile and runs `./make.sh lint` and `./make.sh test` inside the image. It
never knows whether the service uses Ruff, Oxlint, pytest or Playwright.
Formatting happens locally; CI only lints. There are no pre-commit hooks.

## Consequences

- A new service, in any language, joins local development and CI by providing
  a `make.sh` and a Dockerfile.
- Agents can verify a change in any service with the same two commands.
- Changing a linter or test runner is a change inside one service, not in the
  shared pipelines.
- Each `make.sh` is a small amount of duplicated shell per service.

## Alternatives considered

- **A root Makefile or task runner with per-language targets:** one file, but
  every service change edits shared configuration and CI needs every toolchain.
- **Language-specific CI steps:** precise, but couples the shared pipelines to
  each project's stack.
