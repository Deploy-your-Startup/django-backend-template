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

Keep `.copier-answers.yml` in Git. Use `startup template update --dry-run` to
preview template changes, then apply the reviewed version, resolve conflicts
and run affected checks. Do not edit Copier answers manually. Existing Vault
configuration under deployment/group_vars is preserved during updates.
