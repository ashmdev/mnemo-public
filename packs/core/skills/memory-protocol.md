# Core: Memory Protocol

## Purpose

Define when, what, and how to save information to Mnemo so the project accumulates
institutional knowledge that persists across sessions, developers, and time. Good memory
hygiene means future sessions start with context instead of rediscovery.

## When to Use

Every session. Memory storage is not a separate activity — it is woven into the
development workflow. Any time you learn something that would cost time to rediscover,
that is a candidate for storage.

## Instructions

### 1. What to Save

#### Decisions (scope: `architecture` or `convention`)
Choices with alternatives that were deliberately rejected.

```
mnemo store --project <project> --scope architecture \
  --key auth-strategy --content "Chose JWT over session cookies.
  Reason: stateless scaling across multiple services.
  Rejected: sessions (sticky affinity required), OAuth-only (no service-to-service)."
```

#### Bug Fixes (scope: `bug`)
Root cause and fix for non-trivial bugs. Skip typos and obvious mistakes.

```
mnemo store --project <project> --scope bug \
  --key race-condition-user-create --content "Two concurrent user-create requests
  could both pass uniqueness check before either commits. Fix: database-level unique
  constraint + retry logic on conflict. File: internal/user/repo.go:84"
```

#### Discoveries (scope: `discovery`)
Undocumented behavior, surprising API responses, hidden constraints.

```
mnemo store --project <project> --scope discovery \
  --key stripe-webhook-ordering --content "Stripe webhooks can arrive out of order.
  payment_intent.succeeded can arrive before checkout.session.completed.
  Must handle both orderings in webhook handler."
```

#### Preferences (scope: `convention`)
Team and project conventions not captured in linter rules.

```
mnemo store --project <project> --scope convention \
  --key error-naming --content "Error variables: ErrNotFound, ErrConflict.
  Error types: *NotFoundError, *ValidationError. Always wrap with fmt.Errorf %w."
```

#### Patterns (scope: `pattern`)
Recurring solutions that should be applied consistently.

```
mnemo store --project <project> --scope pattern \
  --key http-handler --content "All HTTP handlers follow: parse request -> validate ->
  call service -> map response. Validation happens in handler, not service layer.
  Service returns domain errors, handler maps to HTTP status."
```

### 2. What NOT to Save

- **Trivial facts:** The project uses Go 1.22. (This is in go.mod.)
- **Temporary state:** "Currently debugging the login flow." (Session-scoped, not persistent.)
- **Sensitive data:** API keys, passwords, PII. Never store secrets in Mnemo.
- **Opinions without context:** "I prefer tabs." (Save conventions with rationale, not preferences without reasoning.)
- **Easily discoverable information:** Standard library behavior, well-documented APIs.

### 3. When to Recall

At the start of every task, recall relevant context:

```
mnemo recall --project <project> --scope architecture
mnemo recall --project <project> --scope convention
mnemo recall --project <project> --scope pattern --query "<area you are working in>"
```

Before fixing a bug, check for prior occurrences:

```
mnemo recall --project <project> --scope bug --query "<symptom or area>"
```

### 4. Content Structure

Every memory entry should answer three questions:
1. **What** happened or was decided?
2. **Why** — the reasoning or root cause?
3. **Where** — file paths, endpoints, or components affected?

Keep entries concise. One paragraph is ideal. Two is the maximum. If you need more,
you are documenting an architecture decision and should use a dedicated ADR.

### 5. Key Naming

Use lowercase kebab-case. Be specific enough to find later, general enough to be useful:

- Good: `auth-jwt-strategy`, `user-create-race-condition`, `stripe-webhook-ordering`
- Bad: `decision-1`, `bug`, `important-thing`

## Output Format

No special output. Memory operations are embedded in the workflow. When you store
something, briefly note what was saved:

```
Saved to Mnemo: [scope: architecture] auth-jwt-strategy — JWT chosen over sessions for stateless scaling.
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Session start | Architecture decisions, conventions, patterns for the area |
| Recall | Before fixing bug | Prior bugs in the same area |
| Store | After decision | Architecture and convention choices with rationale |
| Store | After bug fix | Root cause and fix for non-trivial bugs |
| Store | After discovery | Undocumented behavior, surprising constraints |

## Validation Checklist

- [ ] Every architecture decision saved with alternatives and rationale
- [ ] Non-trivial bug fixes recorded with root cause
- [ ] Surprising discoveries documented
- [ ] No sensitive data in stored memories
- [ ] Keys are descriptive and searchable
- [ ] Content is concise (1-2 paragraphs max)
- [ ] Relevant prior memories recalled before starting work
