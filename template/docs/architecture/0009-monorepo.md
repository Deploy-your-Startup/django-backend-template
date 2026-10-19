# One repository per startup

**Status**: Accepted

## Context

A startup's services change together: a feature usually touches the API, the
user interface, its E2E scenario and sometimes the deployment. Agents and
reviewers need the whole change, its tests and its rules in one place.

## Decision

Keep every service of the startup in **one Git repository** with one top-level
directory per service: `backend`, `e2e_tests` and `deployment`. One commit and one pull request carry a complete
change, for example a new route, the page that uses it and the E2E scenario.

- **Services stay independent inside the repository.** Each owns its
  `make.sh`, pinned tools, Dockerfile and `deployment/` (ADR 0005); there is
  no shared root build. `mise.toml` only delegates to the services.
- **CI is selected by path.** Each caller workflow lists the paths of its
  services, so a change builds, tests and deploys only what it affects.
- **One history and one version.** `main` is production; services are not
  versioned or released separately.
- **Rules live next to their code.** The root `AGENTS.md` and the ADRs apply
  to all services; a service's `AGENTS.md` holds only what is specific to it.
- **Shared tooling stays outside.** Ansible roles, reusable workflows and the
  template come from the deploy-your-startup and template repositories, not
  from copies in this repository. Another startup gets its own repository.

## Consequences

- API, client and E2E changes cannot drift across repositories; CI checks
  the generated client and the browser flows against the same commit.
- Every contributor and agent sees the whole system; per-service access
  control is not possible.
- A new service is a new top-level directory with the ADR 0005 contract and
  its own path filters, not a new repository.

## Alternatives considered

- **One repository per service:** independent access and releases, but every
  feature needs coordinated pull requests and version pinning between them.
- **A monorepo build tool (Nx, Turborepo, Bazel):** caching and dependency
  graphs pay off at many services; with a handful, path filters and `make.sh`
  are simpler.
- **One repository for the whole portfolio:** couples unrelated startups'
  history, access and CI.
