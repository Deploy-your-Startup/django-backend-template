# Local consent and operator-owned disclosures

**Status**: Accepted

## Context

Startups need inspectable privacy controls without registering with another
provider. Analytics configuration alone must not imply permission to collect.

## Decision

Keep publication-approved operator details and project-specific privacy notices
in an owner-maintained JSON file. Preserve it during template updates. Mark
unreviewed pages as drafts and disable optional tracking until review.
Vue bundles CookieConsent locally and gates Umami behind opt-in, with reject
and withdrawal controls. Django ships legal pages but no optional tracker.
The CLI validates configuration; it cannot certify legal completeness.

## Consequences

- No consent-provider account or hosted dependency is needed.
- Operators must review disclosures whenever external services or data
  processing change.
- Integration and E2E tests cover public links and the consent lifecycle.
  Production provider behaviour must be verified separately.

## Alternatives considered

- **Hosted consent platforms:** add an account and a remote dependency.
- **A custom banner:** requires maintaining accessible preference dialogs and
  consent persistence.
