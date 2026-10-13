# Backend

Django models and FastAPI routes share one ASGI application. Use the commands
in the root AGENTS.md. Keep business rules, queries and transactions in each
app's `services.py`; routes, views and commands are thin adapters (ADR 0006).

Integration tests are the default; changed user flows require E2E tests.
Unit tests are reserved for complex algorithms (ADR 0001). Use factories, explicit
GIVEN / WHEN / THEN and an empty, isolated database (ADR 0001). Test the real
application and persistence; never mock our own code.
