# Core: Issue Creation

## Purpose

Write issues that give the reader enough context to understand, prioritize, and act on
the problem or request without a follow-up conversation. A good issue is a self-contained
unit of work that anyone on the team can pick up.

## When to Use

When reporting bugs, requesting features, proposing improvements, or tracking technical
debt. If work needs to be done and it is not small enough to just do immediately, create
an issue.

## Instructions

### 1. Bug Reports

A bug report must answer: What happened? What should have happened? How can I reproduce it?

```markdown
## Bug: [Short description of the incorrect behavior]

### Steps to Reproduce
1. Log in as an admin user
2. Navigate to Settings > Billing
3. Click "Update Plan" with no plan selected
4. Observe the error

### Expected Behavior
A validation message should appear: "Please select a plan before updating."

### Actual Behavior
The page crashes with a blank white screen. Browser console shows:
`TypeError: Cannot read property 'id' of undefined at BillingPage.tsx:42`

### Environment
- Browser: Chrome 120.0.6099.109
- OS: macOS 14.2
- App version: 2.3.1 (commit abc1234)
- API environment: staging

### Screenshots / Logs
[Attach screenshot of the error, relevant log output, or network request/response]

### Severity
**High** — Blocks admin billing management, no workaround.

### Additional Context
First noticed after the v2.3.1 deployment. Works correctly on v2.3.0.
Likely introduced by PR #287 (billing page refactor).
```

**Key principles:**
- Reproduction steps must be specific. "Click around the billing page" is not reproducible.
- Include the exact error message, not a paraphrase.
- State the environment. Bugs can be browser-specific, version-specific, or environment-specific.
- Suggest a cause if you have evidence, but separate observation from speculation.

### 2. Feature Requests

A feature request must explain the problem it solves, not just the solution it proposes.

```markdown
## Feature: [Short description of the capability]

### Problem
Users on annual billing plans cannot see a breakdown of their prorated charges
when switching tiers mid-cycle. Support receives ~15 tickets/week asking for
this breakdown, and agents must manually calculate it each time.

### Proposed Solution
Add a "Charge Preview" step to the plan change flow that shows:
- Current plan: name, price, days remaining
- New plan: name, price, prorated amount
- Total charge or credit

Display this before the user confirms the change.

### Alternatives Considered
1. **Email receipt after change:** Does not prevent confusion, still generates support tickets.
2. **FAQ article:** Users do not read FAQ before changing plans (measured: 3% click-through).
3. **Support agent calculator tool:** Reduces agent time but does not reduce ticket volume.

### Acceptance Criteria
- [ ] Preview displays before confirming plan change
- [ ] Prorated amounts match actual Stripe charge within $0.01
- [ ] Preview works for upgrades, downgrades, and same-tier interval changes
- [ ] Mobile-responsive layout

### Priority Justification
**Medium-High.** Reduces support load (~15 tickets/week * 10 min each = 2.5 hrs/week)
and improves user trust during a revenue-critical flow.
```

### 3. Technical Debt / Improvement

```markdown
## Improvement: [Short description]

### Current State
The user search endpoint performs a full table scan on every request.
With 50K users, p95 latency is 800ms. At projected 200K users (Q3),
this will exceed the 2-second SLO.

### Proposed Change
Add a GIN index on `users.name` and `users.email` columns.
Migrate the search query to use `ILIKE` with the index instead of
application-level filtering.

### Impact
- Query time: ~800ms -> ~15ms (measured on staging with 200K test users)
- Migration: Backward compatible, online index creation, no downtime

### Effort Estimate
Small (1-2 hours). Index migration + query update + verification.
```

### 4. Issue Metadata

#### Labels

Use consistent labels to enable filtering and prioritization:

| Category | Labels | Purpose |
|----------|--------|---------|
| Type | `bug`, `feature`, `improvement`, `debt` | What kind of work |
| Priority | `critical`, `high`, `medium`, `low` | How urgent |
| Area | `billing`, `auth`, `api`, `frontend` | Where in the codebase |
| Status | `needs-triage`, `ready`, `blocked` | Workflow state |

#### Priority Definitions

| Priority | Definition | Response Time |
|----------|-----------|---------------|
| **Critical** | System down, data loss, security breach | Immediate |
| **High** | Major feature broken, significant user impact | This sprint |
| **Medium** | Degraded experience, workaround exists | Next sprint |
| **Low** | Minor inconvenience, cosmetic issues | Backlog |

### 5. Linking

- Link to related issues: "Related to #45" or "Blocked by #89"
- Link to PRs that implement the issue: automatic with "Closes #123" in PR description
- Link to relevant documentation, Slack threads, or support tickets
- Reference prior art: "Previous attempt in #67 was reverted because..."

### 6. What Makes a Bad Issue

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| "Fix the bug" | No reproduction steps, no context | Add steps, expected/actual, environment |
| "Make it faster" | No measurement, no target | Add current measurement and target SLO |
| "Refactor everything" | Unbounded scope | Break into specific, measurable tasks |
| "User wants X" | Solution without problem statement | Describe the user problem first |
| Duplicate issue | Fragments discussion | Search before creating, link if related |

## Output Format

When creating an issue, summarize it:

```markdown
### Issue Created
- **Type:** Bug / Feature / Improvement
- **Title:** [issue title]
- **Priority:** Critical / High / Medium / Low
- **Labels:** [applied labels]
- **Links:** Related #45, Blocks #89
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before creating issue | Issue templates, labeling conventions, prior related issues |
| Store | After establishing template | New issue templates, priority definitions |

## Validation Checklist

- [ ] Title clearly describes the issue in one line
- [ ] Bug reports include reproduction steps, expected vs actual, and environment
- [ ] Feature requests describe the problem before the solution
- [ ] Alternatives considered for feature requests
- [ ] Priority assigned with justification
- [ ] Appropriate labels applied
- [ ] Related issues and PRs linked
- [ ] No duplicate of an existing open issue
