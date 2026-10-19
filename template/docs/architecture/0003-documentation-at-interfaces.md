# Documentation at interfaces

**Status**: Accepted

## Context

Repeating a rule across schemas, routes, services and components adds noise
and lets the copies drift apart. Code should explain its mechanics;
documentation should capture the context code alone cannot express.

## Decision

Document a rule once, at its relevant interface: an API schema, a public type,
a use-case entry point, the README, or an ADR.

Comments explain:

- why a non-obvious decision was made;
- business rules and invariants;
- external constraints and intentional exceptions.

Keep comments short and prefer **why** over **what**. Do not comment what clear
code already says. Explain mechanics only when an interface or implementation
remains genuinely hard to read, and simplify the code first when practical.
Remove comments that have become redundant.

Tests are executable specifications. They may be more verbose and repeat
business context when that makes a scenario understandable on its own.

Record a decision that shapes how the project is built as a new ADR in
`docs/architecture/` named `NNNN-short-title.md`, written in English, with a
`**Status**:` line and the sections Context, Decision, Consequences and
Alternatives considered. List it under "Architecture decisions" in `AGENTS.md`
with a note on when an agent should load it.

ADR numbers 0001-0099 are reserved for the template, which delivers and
updates them; gaps in that range stay reserved. Project ADRs start at 0100 and
count up sequentially, so a template update never collides with a project
decision. Change a template ADR through the template, not in the project.
`tests/test_agent_links_integration.py` checks names, headings, unique numbers
and the index.

## Consequences

- Each rule has one authoritative location.
- Implementations carry fewer, more useful comments.
- Tests remain intentionally descriptive.

## Alternatives considered

- **Document every use:** convenient locally, but duplicates information.
- **Avoid comments entirely:** loses rationale and external constraints.
- **Only the README:** separates documentation from the interface it describes.
- **One shared sequence for template and project ADRs:** template updates
  collide with project decisions that took the next free number.
