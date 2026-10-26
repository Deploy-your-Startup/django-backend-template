# Pragmatic modulith and checked import boundaries

**Status**: Accepted

## Context

A startup should be easy to extend without abandoning the framework's useful
features. ADR 0004 chooses the application topology; ADR 0006 places business
logic in per-app services. As the application grows, it also needs a consistent
approach to module boundaries and to what automated checks can establish.

A Django app is a code organization unit. Its folder name alone does not make
it a separate business domain, database owner or independently deployed service.

## Decision

Prefer a **pragmatic modulith**: one application organized around business
capabilities, with clear responsibilities and checked source dependencies.
Start small, keep a feature's code together and add structure when it helps
navigation or change. Do not create empty layers, mandatory repository wrappers,
module-API facades, event buses or deployment units for each new app.

### Framework-native collaboration

Use normal Django model relations, QuerySets, ModelForms, joins and shared
transactions inside the application, including across app folders. Shared user
identity and profile references are allowed. A related set of apps may implement
one business capability; it does not need a database per app.

For example, orders and order lines may live in different apps while retaining
a foreign key and one transaction for placing an order. Do not replace that
relationship with a plain identifier solely to keep a hypothetical extraction
path open.

Entry points parse input, resolve the caller, call services and translate their
results. Services hold use cases, business authorization, queries and transactions
(ADR 0006); they may use Django and the ORM directly and return models or
QuerySets inside the application. ModelForms and straightforward object lookups
remain supported. Models describe data and row invariants and must not depend
on services or entry points. Services must not depend on HTTP entry points or
transport-specific schemas. Keep technical integrations behind focused client
modules where they help.

A service's ownership of a use case is a design convention. Import analysis
cannot reliably distinguish an allowed ORM read from an unauthorized write,
prove that every write went through a particular function or establish that a
view contains no business logic. Use integration tests and review for those
properties rather than promising enforcement that the tool does not provide.

### Architecture checks

Use a maintained analyzer suited to the actual source: Import Linter for Python;
Dependency Cruiser for a JavaScript/TypeScript module graph when the application
has one. Classic browser scripts and framework conventions may have dependencies
that an import graph does not represent. Do not add tools merely for symmetry
between stacks.

When enabling an architecture gate:

- Pin the analyzer and commit its configuration and lockfile with the service.
  Run it through `make.sh lint`, so local and CI checks use the same command.
- Check entry-point → service → model import direction, relevant source-import
  cycles, and production dependencies on tests or test helpers. Framework wiring,
  fixtures and generated sources need explicit scopes. Model relationships are
  not source-import cycles and do not justify a blanket app-independence rule.
- Check actual modules that exist. Required modules disappearing or an intended
  scope matching no source must fail instead of silently passing an empty scan.
  Keep declared source and test inventories current as the application grows.
- Exercise the real analyzer against application sources with both allowed and
  deliberately forbidden dependencies. Normal cross-app model collaboration
  must pass; reverse-layer imports, cycles and test imports must fail with a
  useful diagnostic. Use real parser/resolver settings for aliases, generated
  types and component files where applicable.
- Keep formatting separate: lint checks without modifying source. Explain any
  narrow exception where the configuration permits it.

This ADR defines the shared policy; it does not itself install an analyzer.
A project has an active gate only when its tool, contracts, command integration
and regression checks are present. Document the concrete package/layer mapping
at the configuration, with a project ADR (0100+) only when local rationale or a
deliberate exception needs one. Do not copy this policy into each project ADR.

### Optional independent modules

Use stronger isolation only for a concrete requirement, recorded in a later
project ADR: for example independent operation or a different data-access policy.
Then explicitly define the boundary, public data contracts and permitted calls.
Removing cross-boundary foreign keys, joins and shared transactions requires a
migration plan; it is not a default imposed on every Django app.

Separate databases need routing, migration and backup handling, referential
integrity rules and real multi-database integration tests. Cross-module workflows
need explicit partial-failure and retry semantics. A separate process also needs
network failure handling and compatible contracts. Code organization alone does
not establish database isolation or independent deployability.

## Consequences

- Projects gain a consistent structure while retaining Django's relational
  features and a short path to shipping the next feature.
- App folders can be introduced without replacing existing relations or adding
  public data contracts for every service function.
- Static checks establish configured source dependencies; integration and
  browser tests remain necessary for behavior, permissions and data integrity.
- Individual projects maintain concrete import scopes. Stronger boundaries and
  data migrations are deliberate later decisions rather than template defaults.

## Alternatives considered

- **Strict independent modules from the start:** gives stronger potential
  extraction boundaries, but trades useful ORM relations and transactions for
  manual integrity and distributed-workflow concerns before they are needed.
- **Documentation alone:** records intent without catching structural drift.
- **Read-only cross-module model access enforced with imports:** imports do not
  reliably identify whether the caller reads, writes or traverses a relation.
- **Microservices or strict Clean Architecture by default:** adds operational
  or abstraction costs without an established product need.
