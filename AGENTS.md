# django-backend-template contributor instructions

This repository supplies the shared foundation for Deploy Your Startup.
Read README.md and the existing workflows before changing it. Keep public
instructions self-contained, in concise English, with neutral sample names.
Users retain ownership of their code, accounts, servers and credentials.

## Tests and runtime

Follow [Testing policy and completion evidence](docs/testing-policy.md).
Generated backends collect business logic in per-app services.py (ADR 0006).
Run mise run template:check and the generated-project workflow.
Use global uv with the committed .python-version and run project commands
through mise. Formatting may write; lint must only check. Do not add git hooks.

## Generated project harness

Generated projects carry their own agent instructions: template/AGENTS.md,
template/CLAUDE.md, .github/git-commit-instructions.md and the ADRs in
template/docs/architecture/. Treat them as part of the product. Keep the
template's own code compliant with them (the linters enforce what they can),
add an ADR when the template makes a new structural decision, and keep the
ADR list in template/AGENTS.md in sync. CI checks that they ship.
Carry recurring application fixes into this foundation with a regression check;
keep generated instructions concise and preserve application customizations.

## Release and operations

Check README, agent instructions, metadata, license and public version refs
together. Release only tested commits and pin consumer versions. Local checks
do not prove successful cloud provisioning or production deployment.
Use startup CLI for Vault, provisioning, deployment and shared-role sync.
Never log or commit real credentials. Secret values use stdin and Keychain;
preview changes with --dry-run. Ask before destructive or costly operations.

Keep application template updates (startup template update) separate from
shared deployment updates (startup sync). Preserve application customizations
and deployment/group_vars. Never hand-edit deployment/.shared-roles.
