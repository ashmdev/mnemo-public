# Quality: Commit Hygiene

## Purpose

Produce clean, meaningful commit history that tells the story of WHY the codebase changed.
Good commits make bisecting, reviewing, reverting, and onboarding faster.
Mnemo remembers project-specific commit conventions so they're enforced consistently.

## When to Use

- Every time you create a commit
- User says "commit", "commitear", "guardar cambios"
- Before creating a PR (clean up history)
- When reviewing commit messages for quality

## Instructions

### 1. Conventional Commit Format

```
{type}({scope}): {description}

{optional body — explain WHY, not WHAT}

{optional footer — breaking changes, issue refs}
```

**Types** (exhaustive list):

| Type | When | Semver |
|------|------|--------|
| `feat` | New user-facing feature | minor |
| `fix` | Bug fix | patch |
| `refactor` | Code change that neither fixes nor adds | none |
| `perf` | Performance improvement | patch |
| `test` | Adding or correcting tests | none |
| `docs` | Documentation only | none |
| `chore` | Build, CI, deps, tooling | none |
| `ci` | CI/CD configuration | none |
| `style` | Formatting, whitespace (no logic change) | none |
| `revert` | Reverting a previous commit | varies |

**Scope**: The area affected (auth, api, ui, db, config, etc.)

### 2. Message Rules

- **Subject line**: max 72 chars, imperative mood ("Add" not "Added")
- **Body**: wrap at 80 chars, explain motivation and context
- **No generic messages**: ❌ "fix", "update", "changes", "wip", "stuff"
- **No implementation details in subject**: ❌ "Change line 45 of auth.go"
- **Reference issues**: `Closes #123`, `Refs #456`

**Good examples:**
```
feat(auth): add JWT refresh token rotation

Tokens now rotate on each refresh to prevent replay attacks.
Previous tokens are invalidated immediately.

Closes #234
```

```
fix(api): handle nil pointer in user lookup

UserService.Find() could return nil when the user was deleted
between the auth check and the lookup. Added explicit nil guard.

Fixes #567
```

**Bad examples:**
```
❌ fixed stuff
❌ update auth
❌ WIP
❌ changes
❌ fix: fix the fix that fixed the bug
```

### 3. Atomic Commits

One logical change per commit:
- ❌ "Add feature + fix unrelated bug + update deps"
- ✅ Three separate commits, each with clear purpose

If you have mixed changes, use `git add -p` to stage selectively.

### 4. Pre-Commit Checks

Before committing, verify:
- `git diff --staged` shows only intended changes
- No secrets (.env, API keys, tokens) in staged files
- No large binary files accidentally staged
- Tests pass for the staged changes

### 5. Breaking Changes

For breaking changes, add footer:
```
feat(api): change response format to JSON:API

BREAKING CHANGE: API responses now follow JSON:API spec.
Clients must update their parsers. See migration guide in docs/api-v2.md.
```

### 6. Save Conventions to Memory

When discovering or establishing commit conventions for a project:
```
mem_save(
  title: "Commit convention: {convention}",
  type: "pattern",
  project: "{project}",
  topic_key: "conventions/commits",
  content: "## Convention\n{description}\n## Examples\n{good examples}\n## Rationale\n{why}"
)
```

Search Mnemo for existing conventions before suggesting new ones:
```
mem_search(query: "commit convention", project: "{project}", type: "pattern")
```

## Graceful Degradation

- If Mnemo unavailable → follow conventions without memory lookup/save
- If no project conventions found → use defaults above
