# Deployment

- Keep infrastructure declarative and reproducible, aligned with the local
  Compose setup and CI.
- Use the startup CLI for provisioning, deployment, Ansible and Vault. Preview
  changes with `--dry-run` and call out destructive or replacing operations.
- Do not provision, deploy, restore or destroy anything unless the user asks
  for it explicitly; these operations can cost money or lose data.
- Never commit or print secrets, decrypted Vault files, credentials or
  personal environment overrides.
- Pin image, role, workflow and tool versions; make upgrades explicit and
  reviewable.
- Use least privilege and safe defaults. Do not expose a service publicly
  without a documented reason.
- Never hand-edit `.shared-roles`; refresh them with `startup sync`.
