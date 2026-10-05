# Deploy your Startup — Django template

A versioned Copier template for Django + FastAPI services, maintained through
startup CLI. The generated project lives under `template/`; instructions for
maintainers and the source projects are in [TEMPLATE.md](TEMPLATE.md).

```bash
startup bootstrap --template https://github.com/Deploy-your-Startup/django-backend-template.git --template-version <tag-or-commit>
```

This repository is not an application checkout. Generate a test project before
running its service tasks. CI generates the project and checks backend lint,
backend tests and the Playwright browser smoke test.
