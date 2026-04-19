# Core: Branch Workflow

## Purpose

Maintain a clean, predictable branching strategy that supports parallel development,
safe experimentation, and smooth code integration. A consistent workflow reduces
merge conflicts, keeps the main branch stable, and makes the project history useful.

## When to Use

Every time you create a branch, open a PR, or merge code. The workflow applies to
all changes, from single-line fixes to multi-week features.

## Instructions

### 1. Branch Naming

Use a prefix that describes the type of work:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/user-search` |
| `fix/` | Bug correction | `fix/login-timeout` |
| `refactor/` | Restructuring, no behavior change | `refactor/extract-billing-service` |
| `docs/` | Documentation only | `docs/api-rate-limits` |
| `chore/` | Tooling, CI, dependencies | `chore/upgrade-go-1.23` |
| `test/` | Test-only changes | `test/billing-edge-cases` |

**Naming rules:**
- Lowercase with hyphens: `feature/user-search` not `Feature/UserSearch`
- Short but descriptive: `fix/null-pointer-user-lookup` not `fix/bug`
- Include ticket number when applicable: `feature/PROJ-123-user-search`

### 2. Branch Lifecycle

```
main (stable, always deployable)
  |
  +-- feature/user-search (created from main)
  |     |
  |     +-- commits...
  |     |
  |     +-- PR opened, reviewed, merged back to main
  |
  +-- fix/login-timeout (created from main)
        |
        +-- commits...
        |
        +-- PR opened, reviewed, merged back to main
```

- Always branch from `main` (or your project's integration branch).
- Never commit directly to `main`.
- Delete branches after merge.

### 3. Pull Request Standards

**Title format:** Same as commit convention — `type(scope): description`

```
feat(search): add full-text search for articles
fix(auth): handle expired refresh tokens gracefully
```

**Description template:**

```markdown
## What
<One paragraph: what this PR does>

## Why
<One paragraph: why this change is needed, link to issue>

## How
<Brief description of the approach taken>

## Testing
<How to verify: tests added, manual steps, or both>

## Notes
<Anything reviewers should know: trade-offs, follow-ups, risks>
```

### 4. Draft PRs for Early Feedback

Open a draft PR when:
- You want architectural feedback before completing the implementation
- The approach is novel or risky and you want a sanity check
- The change is large and you want incremental review

Mark clearly in the description: "Draft: seeking feedback on approach, not ready for merge."

### 5. Rebase vs Merge

**Rebase** your feature branch onto main before opening/updating a PR:

```bash
git fetch origin
git rebase origin/main
```

This keeps the history linear and makes the PR diff clean.

**When to rebase:**
- Updating your branch with changes from main
- Cleaning up local history before opening a PR
- Squashing WIP commits into meaningful units

**When NOT to rebase:**
- Shared branches that others are working on (rebase rewrites history)
- After the PR is approved and awaiting merge (changes the commit hashes reviewers approved)

**Merge** is the strategy for integrating PRs into main:
- Use merge commits (not fast-forward) so the PR boundary is visible in history
- Squash-merge for PRs that are a single logical change with noisy interim commits

### 6. Keeping Branches Current

- Rebase onto main at least daily for long-lived branches
- If your branch is more than a week old without merging, something is wrong:
  - The PR is too large (split it)
  - The review is blocked (escalate)
  - The feature is stalled (communicate)

### 7. Branch Hygiene

- Delete merged branches immediately (local and remote)
- Never reuse branch names
- Periodically prune stale remote references: `git fetch --prune`

```bash
# After merge
git branch -d feature/user-search
git push origin --delete feature/user-search

# Prune stale references
git fetch --prune
```

## Output Format

When creating a branch or PR, summarize the action:

```markdown
Branch created: feature/user-search (from main at abc1234)
PR opened: #42 feat(search): add full-text search for articles
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before branching | Branch naming conventions, PR template |
| Store | When convention changes | Updated branching rules, merge strategy decisions |

## Validation Checklist

- [ ] Branch created from current main with correct prefix
- [ ] Branch name is lowercase, hyphenated, and descriptive
- [ ] PR title follows `type(scope): description` format
- [ ] PR description includes What, Why, How, and Testing sections
- [ ] Branch rebased onto current main before PR review
- [ ] No direct commits to main
- [ ] Branch deleted after merge
