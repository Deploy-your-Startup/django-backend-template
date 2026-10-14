# Public legal information and privacy

Edit `backend/project/site-policy.json` with publication-approved operator data. Never copy a private
address from unrelated sources. `operatorName`, `operatorAddress`, `contactEmail`,
`additionalImprint` and `privacyNotice` are rendered as text, not HTML.
The notice must describe this project's actual hosting/logging, contact handling,
authentication, analytics and other providers: purposes, legal bases, recipients,
transfers, retention, rights and complaint/contact routes. A generic placeholder
is not a reviewed notice. Confirm applicable operator/register details.

Set `reviewed: true` only after reviewing the complete configuration. Draft pages
remain explicitly labelled. Run `startup doctor --project-dir .` with a CLI
revision supporting site policies. This checks configuration presence and types;
it does not certify legal compliance or verify production behaviour.

`startup bootstrap --site-policy /absolute/path/to/operator.json` can install a
reviewed public configuration with compatible CLI/template revisions. Existing
operator policy files are preserved by Copier updates. No additional account is
needed. Template updates do not deploy, and shared deployment sync does not add
these application files.

The Django template has no optional analytics integration: keep `analytics: "off"`.
It provides `/impressum` and `/privacy`, with links on both pages and the admin
login. No consent banner or JavaScript library is loaded for necessary login
cookies alone. If adding analytics later, add consent gating and browser tests
before enabling it; do not merely change this configuration flag.

Integration tests cover anonymous legal routes, draft warnings and admin links.
The browser suite follows the links before login. Operator-specific disclosures
and production cookie/hosting behaviour still require review.
