# Backend

Django models and FastAPI routes share one ASGI application. Use the commands
in the root AGENTS.md. Keep business rules, queries and transactions in each
app's `services.py`; routes, views and commands are thin adapters (ADR 0006).

Follow [Testing policy and completion evidence](../docs/testing-policy.md) and
[ADR 0001](../docs/architecture/0001-test-strategy.md): factories and an empty,
isolated database per test.

Import checks run in `make.sh lint` (ADR [0011](../docs/architecture/0011-module-boundaries.md)).
Extend the concrete scopes in `tach.toml` when adding apps or layers.
