# Explicit function signatures

**Status**: Accepted

## Context

Python lets a function's signature stay unannotated, so the shape of a
function becomes a side effect of its body. Changing the body changes the
contract silently, and the type checker cannot report the break where it
happened.

## Decision

Every named function and method in production code declares its parameter and
return types. `-> None` is written out, not omitted.

Ruff's `ANN` rules enforce it, so the rule does not depend on review.
`ANN401` is ignored because `Any` is sometimes the honest type at a framework
boundary. If a TypeScript frontend is added, enforce the same rule there with
Oxlint's `typescript/explicit-function-return-type`.

Test code is exempt: its signatures carry no contract for other code. A helper
that moves from test code into production code acquires the requirement.

## Consequences

- A change to a function's result is reported at that function and shows up in
  the diff as an edited signature.
- Readers and agents learn the contract from the signature without reading the
  body.
- Some signatures get verbose at framework boundaries.

## Alternatives considered

- **Annotate only module boundaries:** half the annotations, but internal
  helpers stay unannotated and their contracts drift unnoticed.
- **Convention without lint:** costs nothing to adopt and is not upheld under
  review pressure.
