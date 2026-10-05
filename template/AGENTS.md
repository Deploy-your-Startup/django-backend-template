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

Tests create entities through factories, use GIVEN / WHEN / THEN and start with
an empty database. Keep business logic in services and routes/views thin.
E2E uses a separate database and server; never point its flush at development
or production data. Local Postgres is started by Compose only when DATABASE_URL
is absent. Configure LOCAL_DB_NAME and POSTGRES_PORT for concurrent stacks.

Always use startup CLI for deployment, Ansible and Vault operations. Never print
or persist decrypted secrets. Ask before destructive restore or secret rotation.

## Template updates (Copier)

From the repo root with a clean working tree:

```bash
startup template update --version main --dry-run
startup template update --version main
```

Review the diff, resolve conflicts, run affected lint/tests/E2E, then commit
including `.copier-answers.yml`. A separate branch is optional; Copier does
not commit, push or deploy. Use a tag/commit instead of `main` for a fixed target.
Do not edit Copier answers manually. Existing deployment/group_vars files are
preserved. `startup sync` handles shared deployment roles/workflows separately.
