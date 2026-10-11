# Business logic in services.py

**Status**: Accepted

## Context

The same business action may be triggered by a page, an API route or a command.
Putting its rules in those entry points duplicates behaviour and makes changes
hard to follow.

## Decision

Use **`services.py` per Django app or business area**, for example
`games/services.py`. It holds the business use cases: rules, database queries,
transactions and side effects. Use descriptive function names such as
`submit_suggestion`; do not introduce service classes just to wrap functions.

Views, routes and management commands are thin adapters: parse input, resolve
the caller, call a service and translate its result or business error into the
appropriate response. Business permissions belong with the use case so another
entry point cannot bypass them. Models describe data, constraints and row
invariants; workflows spanning objects belong in services.

```python
# api/routes.py — HTTP adapter
@router.post("/entries", response_model=EntryResponse)
def create_entry(data: EntryRequest) -> Entry:
    return services.create_entry(data.title)

# api/services.py — business action and persistence
def create_entry(title: str) -> Entry:
    return Entry.objects.create(title=title.strip())
```

Keep one module per business area, not one giant project-wide collection.
Split a growing module by use case when it becomes hard to navigate. Small
adapters do not need an extra abstraction for every line of code.

Test use cases through integration tests with real persistence and collaborators;
cover user flows through E2E (ADR 0001). Do not unit-test or mock services.

## Consequences

- Entry points share one implementation of the business rules.
- A feature's behaviour is easy to locate and review.
- The service boundary stays simple; it is not a repository layer or a framework.

## Alternatives considered

- **Business logic in views or routes:** duplicates rules across callers.
- **Everything on models:** mixes stored data with multi-object workflows.
- **One service class per action:** adds ceremony without a concrete need.
