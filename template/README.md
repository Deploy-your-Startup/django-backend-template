## Local development environment

This project is generated with Copier through `startup bootstrap`. Keep
`.copier-answers.yml` committed; it records the template source, baseline and
public project parameters used for future updates.

Install the shared machine setup first, then use the global `uv` installation
with the Python version committed in each service's `.python-version` file.
Mise exposes the existing development commands without managing Python or uv:

```bash
mise tasks
mise run backend:dev
mise run backend:lint
mise run backend:test
```

Running `uv sync` or any mise task in `backend/` and `deployment/` automatically
selects that service's Python version.

`./backend/make.sh setup_local` installs locked dependencies using the globally
installed uv. It never installs a separate global formatter.

The backend uses Django and FastAPI in one ASGI application. Backend tests use
pytest-django; create entities through factories, use GIVEN / WHEN / THEN, and
start every test with an empty database.

`project.htmx` supplies event/toast responses, `project.images` handles image
resizing/compression, and `project.testing` supplies temporary media directories
and upload fixtures. Put application logic in services and keep views thin.

Local Postgres starts automatically through `backend/docker-compose.yml` with
a health check. Set DATABASE_URL to use an existing database (production and CI
never start Docker). LOCAL_DB_NAME and POSTGRES_PORT isolate concurrent stacks.
The development server also accepts `--port`, `--reload`, `--flush` and
`--database_url`.

The Playwright starter checks the real ASGI server with an isolated database:

```bash
cd e2e_tests
./make.sh setup_local
./make.sh test_e2e
```

To update an existing project, first commit your local changes, then review a
preview and apply the same template version:

```bash
startup template update --version <template-tag-or-commit> --dry-run
startup template update --version <template-tag-or-commit>
```

Review the diff, resolve any conflicts and run affected checks before committing.
Updates do not commit, push or deploy. Vault configuration under group_vars is
preserved; use startup's deployment/secrets commands to maintain it.
