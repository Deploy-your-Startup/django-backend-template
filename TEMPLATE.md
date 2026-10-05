# Maintaining the Django template

Copier renders this repository using `copier.yml`. The custom delimiters retain
the existing `§§deploy_your_startup.<field>§§` placeholders while leaving Django,
Ansible, GitHub Actions and Docker template syntax untouched. No template tasks
or migrations execute shell commands.

The reusable foundation comes from gaming-buch-club (pytest-django, isolated
development servers, factory-based tests) and about-phil (Compose Postgres with
health checks and an explicit DATABASE_URL bypass). Application-specific games,
Vue, oauth2-proxy and AI services are intentionally owned by their projects.

The latest gaming-buch-club service refactor also supplies generic HTMX response
helpers, image resizing/compression, isolated upload-test helpers and their
image tests. New apps should keep business logic in services and views thin.

`deployment/group_vars/*.yml` seeds a new project but is preserved on updates.
Copier answers contain only public parameters, never tokens or private keys.
Vault encryption and provisioning remain the responsibility of startup CLI.

Release tested commits with version tags. A consumer stores the exact source
and baseline in `.copier-answers.yml`. The CLI also accepts an explicit commit
or branch while reviewing an unpublished template release.

After rendering a test project, run:

```bash
mise run backend:lint
mise run backend:test
cd e2e_tests && ./make.sh setup_local && ./make.sh test_e2e
```

Use a dedicated database for the checks. E2E defaults to port 8001 and Postgres
port 55432; it never reuses a server or database from local development.

Existing projects are adopted from a selected baseline without copying files.
Their current differences are treated as customizations, including missing
files. This does not retroactively pull in earlier template improvements.

The template CI renders a fresh project before running the service contracts,
so unresolved placeholders and cross-language delimiter regressions are tested.
