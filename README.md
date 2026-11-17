# Deploy your Startup — Django template

A versioned Copier template for Django + FastAPI services, maintained through
startup CLI. The generated project lives under `template/`; instructions for
maintainers and the source projects are in [TEMPLATE.md](TEMPLATE.md).

Follow the [public prerequisites](https://deploy-your-startup.com/get-started)
first: macOS, Chrome, GitHub, Hetzner Cloud and an owned domain. Servers and
domains are billed directly by their providers. Then install and verify the CLI:

```bash
curl -fsSL https://deploy-your-startup.com/install.sh | bash
gh auth login -h github.com -p https -s repo,workflow,read:packages,write:packages
gh auth setup-git
startup doctor
startup bootstrap --kind fullstack --provider hetzner --domain-owned \
  --project-name my-startup --base-domain example.com \
  --template https://github.com/Deploy-your-Startup/django-backend-template.git \
  --without-auth
```

Use your own project name and domain. Verify GitHub Actions, DNS, HTTPS and the
application health before calling the first deployment complete. Generated
projects call `Deploy-your-Startup/deploy` (`deploy_repository`, or a fork) and are
pinned to one of its releases (`deploy_ref`); `startup update` moves a project to a
newer release and `startup template update` updates application files.

This repository is not an application checkout. Generate a test project before
running its service tasks. CI generates the project and checks backend lint,
backend tests and the Playwright browser smoke test.

The generated project's deployment version is configured once in
`.github/workflows/startup.yml`. Other workflows and local CLI operations use
that reference. `startup update` changes it; no separate role pin or checksum
files are required. A successful Actions deployment run records execution.

The CLI selects its tested template release by default; use `--template-version`
to select another published release deliberately. Single-version deployment
requires CLI v0.1.52 or newer.
