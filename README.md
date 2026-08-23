## Local development environment

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
