# Core: Commit Hygiene

## Purpose

Produce clean, meaningful commit history that tells the story of *why* the codebase
changed. Good commits make bisecting, reviewing, reverting, and onboarding faster.
Bad commits make all of those painful.

## When to Use

Every time you commit. This is not optional hygiene — it is the baseline for
professional version control.

## Instructions

### 1. Commit Message Format

Follow Conventional Commits:

```
type(scope): short description

Optional body explaining WHY, not WHAT.
The diff shows what changed; the message explains the reasoning.

Refs: #123
```

**Types:**

| Type | When | Example |
|------|------|---------|
| `feat` | New user-facing functionality | `feat(auth): add password reset flow` |
| `fix` | Bug correction | `fix(api): return 404 instead of 500 for missing user` |
| `refactor` | Code restructuring, no behavior change | `refactor(repo): extract query builder from repository` |
| `docs` | Documentation only | `docs(api): add rate limit section to README` |
| `test` | Adding or fixing tests only | `test(auth): add edge cases for token expiration` |
| `chore` | Tooling, deps, CI, config | `chore(deps): upgrade stripe-go to v76` |

**Scope** is the area affected: a package name, module, or feature area. Keep it short.

### 2. Subject Line Rules

- Imperative mood: "add" not "added" or "adds"
- Lowercase after the colon
- No period at the end
- Under 72 characters total
- Specific: "fix null pointer in user lookup" not "fix bug"

### 3. When to Split Commits

One commit = one logical change. Split when:

- A refactor is needed before a feature. Commit the refactor first.
- Tests and implementation are separable. Commit tests that define the behavior, then the implementation that satisfies them.
- You touched unrelated code. Formatting changes, import cleanup, and typo fixes get their own commit.
- The diff is hard to review as one unit. If a reviewer would struggle to hold the full change in their head, split it.

```
# Good: two commits
refactor(user): extract validation into separate function
feat(user): add email verification on signup

# Bad: one commit
feat(user): add email verification and refactor validation
```

### 4. When to Squash

Squash when multiple commits represent incomplete iterations toward a single change:

- "WIP", "fixup", "oops" commits should be squashed before merge
- Multiple attempts at the same fix should become one clean commit
- Interactive rebase before opening a PR: `git rebase -i main`

### 5. Commit Body

Use the body for non-obvious reasoning:

```
fix(billing): prorate subscription changes instead of charging full amount

Customers on annual plans were charged the full monthly rate when
switching tiers mid-cycle. The Stripe API supports proration natively
but we were passing proration_behavior=none. Changed to
proration_behavior=create_prorations.

Discovered during support ticket #4521.
```

Skip the body when the subject line tells the complete story:

```
fix(typo): correct "recieve" to "receive" in error message
```

### 6. References

Link to issues, tickets, or PRs when relevant:

```
Refs: #123
Closes: #456
See: JIRA-789
```

### 7. What Never to Commit

- Secrets, credentials, API keys (use .gitignore and pre-commit hooks)
- Generated files (build output, compiled assets) unless the project explicitly tracks them
- Large binary files (use Git LFS if needed)
- Editor/IDE configuration files (.idea/, .vscode/ settings)

## Output Format

No special output format. Commits speak for themselves in `git log`:

```
$ git log --oneline -5
a1b2c3d feat(search): add full-text search for articles
d4e5f6g refactor(search): extract indexing logic from handler
7h8i9j0 fix(api): handle empty query parameter gracefully
k1l2m3n test(search): add integration tests for search ranking
o4p5q6r chore(deps): upgrade elasticsearch client to v8
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before committing | Project commit conventions, scope naming |
| Store | When establishing convention | New scope names, commit message patterns |

## Validation Checklist

- [ ] Message follows `type(scope): description` format
- [ ] Subject line is imperative mood, under 72 characters
- [ ] Each commit contains exactly one logical change
- [ ] No WIP, fixup, or "oops" commits in the final history
- [ ] Body explains *why* for non-obvious changes
- [ ] No secrets or generated files in the commit
- [ ] Related issues/tickets referenced where applicable
