# Pragmatic modulith and import checks

**Status**: Accepted

## Context

We need maintainable module boundaries without giving up Django's ORM features.

## Decision

Build one application organized by business capability. Entry points call
services (ADR 0006); models must not import services or entry points. Cross-app
model references, joins and shared transactions are allowed.

Ship pinned Tach checks for Python and Dependency Cruiser for Vue.
`make.sh lint` checks cycles, production-to-test imports and existing layers.
Extend the starter configurations when adding apps or layers. Regression tests
exercise the real analyzers with allowed and forbidden imports.

## Consequences

Import checks do not prove ORM write ownership or database isolation. Separate
databases require a concrete need, a project ADR and a migration plan. Project
ADRs record local mappings and exceptions rather than repeating this policy.

## Alternatives considered

Strict app isolation adds constraints before needed; documentation alone cannot
catch dependency regressions.
