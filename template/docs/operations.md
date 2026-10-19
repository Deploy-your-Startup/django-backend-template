# Operations

## Template updates (Copier)

From the repo root with a clean working tree:

```bash
startup template update --version <release-tag> --dry-run
startup template update --version <release-tag>
```

Review the diff, resolve conflicts, run affected lint/tests/E2E, then commit
including `.copier-answers.yml`. Copier does not commit, push or deploy. Do not
edit Copier answers manually. Existing deployment/group_vars files are
preserved. `startup sync` handles shared deployment roles and workflows
separately. Treat the agent harness drift warning as a finding.
