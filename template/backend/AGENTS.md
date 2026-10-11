# Backend

Django models and FastAPI routes share one ASGI application. Use the commands
in the root AGENTS.md. Keep business rules, queries and transactions in each
app's `services.py`; routes, views and commands are thin adapters (ADR 0006).

Integration and E2E tests only, never unit tests. Use factories, explicit
GIVEN / WHEN / THEN and an empty, isolated database (ADR 0001). Test the real
application and persistence; never mock our own code.
