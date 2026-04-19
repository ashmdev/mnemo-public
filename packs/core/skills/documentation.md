# Core: Documentation

## Purpose

Write documentation that helps people use, maintain, and contribute to the project.
Good documentation answers real questions at the moment they arise. Bad documentation
is either absent, outdated, or tells you what you can already see in the code.

## When to Use

When writing public APIs, making architecture decisions, setting up projects, or
changing behavior that others depend on. Not every line of code needs a comment,
but every boundary needs documentation.

## Instructions

### 1. Code Comments: Why, Not What

The code shows *what* happens. Comments explain *why* it happens that way.

```go
// BAD — restates the code
// increment counter by 1
counter++

// BAD — obvious from the function name
// GetUser gets a user
func GetUser(id string) (*User, error) {

// GOOD — explains non-obvious reasoning
// Retry up to 3 times because the upstream payment API has transient 503 errors
// during their maintenance window (daily 02:00-02:15 UTC).
for attempt := 0; attempt < 3; attempt++ {

// GOOD — documents a constraint
// Must hold mu.Lock before calling. The caller is responsible for synchronization
// because this function is called in both single-threaded init and concurrent request paths.
func (c *Cache) evictExpired() {
```

### 2. When to Write Comments

- **Non-obvious business logic:** Why a discount caps at 50%, why retry count is 3
- **Workarounds:** Temporary hacks that compensate for external bugs or limitations
- **Performance decisions:** Why this uses a map instead of a slice, why queries are batched
- **Concurrency contracts:** What locks protect what data, who is responsible for synchronization
- **Magic numbers:** If a number is not self-evident, name it or comment it

### 3. API Documentation

Every public function, method, type, and constant needs documentation:

```go
// CreateInvoice generates a new invoice for the given subscription period.
// It calculates prorated amounts for mid-cycle changes and applies any
// active discounts. Returns ErrNoActiveSubscription if the customer has
// no active subscription.
func (s *BillingService) CreateInvoice(customerID string, period Period) (*Invoice, error)
```

Minimum for public API docs:
- What the function does (one sentence)
- Parameter semantics (if not obvious from types and names)
- Return value meaning
- Error conditions
- Side effects (if any)

### 4. Architecture Documentation

Record significant decisions using Architecture Decision Records (ADRs):

```markdown
# ADR-003: Use PostgreSQL for Primary Storage

## Status
Accepted (2025-11-15)

## Context
We need a primary database for the billing service. The data is relational
(invoices, line items, customers, subscriptions) with complex queries for
reporting.

## Decision
Use PostgreSQL 16 with the pgx driver.

## Alternatives Considered
- **MySQL:** Less robust JSON support, weaker CTE performance
- **MongoDB:** Schema flexibility unnecessary, joins would require application-level logic
- **SQLite:** Single-writer limitation incompatible with concurrent API servers

## Consequences
- Team must maintain PostgreSQL expertise
- Migration tooling needed (chose golang-migrate)
- Strong query capabilities reduce application-layer data manipulation
```

Store ADRs in `docs/adr/` or equivalent, and also save key decisions to Mnemo.

### 5. README Structure

Every project needs a README that answers five questions:

```markdown
# Project Name

One-line description of what this project does.

## Getting Started

Prerequisites, installation steps, and how to run locally.
Copy-paste commands that work on a clean machine.

## Usage

How to use the project. For a library: import and basic examples.
For a service: API overview and common operations.

## Development

How to run tests, lint, build. What the directory structure looks like.
How to add a new feature (which files, which patterns).

## Contributing

How to submit changes. Branch naming, PR process, code review expectations.
Link to more detailed contributing guide if needed.
```

### 6. Keeping Documentation Current

Outdated documentation is worse than no documentation — it creates false confidence.

- **Update docs in the same PR as code changes.** Not in a follow-up. Not "later."
- **Delete documentation for removed features.** Dead docs mislead.
- **Date architecture decisions.** Context changes; knowing when a decision was made matters.
- **Review docs during code review.** If the PR changes behavior, check if docs need updating.

### 7. What NOT to Document

- **Implementation details that change frequently.** These go stale fast. Let the code speak.
- **Things the type system already enforces.** If the parameter is `string`, do not document "this is a string."
- **Opinions disguised as documentation.** "This is the best approach" is not documentation.
- **Internal details in public docs.** Public API documentation should not expose implementation.

## Output Format

When documenting a new component or decision:

```markdown
### Documentation Added
| Type | Location | Describes |
|------|----------|-----------|
| API docs | `billing/invoice.go` | Public functions on BillingService |
| ADR | `docs/adr/003-postgresql.md` | Database selection rationale |
| README | `README.md` | Updated setup instructions |
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before documenting | Existing documentation conventions, ADR format |
| Store | After architecture decision | Key decisions with context and alternatives |
| Store | After establishing convention | Documentation standards and templates |

## Validation Checklist

- [ ] All public APIs have doc comments explaining purpose, params, returns, errors
- [ ] Comments explain *why*, not *what*
- [ ] Architecture decisions recorded as ADRs
- [ ] README covers getting started, usage, development, contributing
- [ ] Documentation updated in the same PR as code changes
- [ ] No stale documentation for removed/changed features
- [ ] No secrets, internal details, or credentials in documentation
