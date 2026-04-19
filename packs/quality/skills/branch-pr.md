# Quality: Branch & Pull Request Workflow

## Purpose

Enforce a professional git workflow: issue-first development, standardized branch naming,
conventional commits, and thorough PR descriptions. Every PR tells a complete story.
Mnemo tracks PR patterns so the team converges on consistent practices.

## When to Use

- User says "create PR", "open pull request", "branch", "crear PR", "abrir PR"
- Starting work on a new feature or fix
- Ready to submit changes for review
- After completing an implementation

## Instructions

### 1. Branch Naming Convention

Format: `{type}/{issue-number}-{short-description}`

| Type | When |
|------|------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `refactor/` | Code restructuring without behavior change |
| `chore/` | Maintenance, deps, CI |
| `docs/` | Documentation only |
| `test/` | Adding or fixing tests only |

Examples:
- `feature/123-user-auth`
- `fix/456-null-pointer-login`
- `refactor/789-extract-service`

**Validation regex**: `^(feature|fix|refactor|chore|docs|test)/[0-9]+-[a-z0-9-]+$`

### 2. Issue Linkage

Every branch MUST be linked to an issue:
- If no issue exists → create one first (use `issue-creation` skill)
- Include `Closes #123` or `Fixes #123` in the PR body
- Reference the issue number in the branch name

### 3. Commit Standards

Follow conventional commits within the branch:

```
{type}({scope}): {description}

{optional body}

{optional footer}
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`
- `feat` → triggers minor version bump
- `fix` → triggers patch version bump
- `BREAKING CHANGE:` in footer → triggers major version bump

### 4. Pre-PR Checklist

Before creating the PR, verify:

- [ ] Branch is up to date with target (`git rebase` or `git merge`)
- [ ] All tests pass locally
- [ ] Linting passes with no new warnings
- [ ] No TODO/FIXME left in changed files (search: `grep -r "TODO\|FIXME" {changed files}`)
- [ ] No debug code left (`console.log`, `print()`, `fmt.Println` for debug)
- [ ] Commit history is clean (squash fixups if needed)

### 5. PR Description Template

```markdown
## Summary
[1-3 bullet points of what changed and why]

## Changes
- [Specific change 1]
- [Specific change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing done: [describe scenario]

## Screenshots
[If UI changes — before/after]

## Related
- Closes #{issue-number}
- Related to #{other-issue}
{Mnemo context: prior decisions or patterns from memory}
```

### 6. Context from Memory

Before creating the PR, search for relevant context:
```
mem_search(query: "{feature/module being changed}", project: "{project}", type: "decision")
mem_search(query: "{files changed}", project: "{project}", type: "pattern")
```

Include relevant prior decisions in the PR description under "Related".

### 7. Save PR to Memory

After creating the PR:
```
mem_save(
  title: "PR #{number}: {title}",
  type: "decision",
  project: "{project}",
  topic_key: "prs/{pr-number}",
  content: "## PR\n{title}\n## Changes\n{summary}\n## Files\n{key files}\n## Link\n{url}"
)
```

## Graceful Degradation

- If Mnemo unavailable → skip memory search/save, follow workflow normally
- If GitHub CLI unavailable → output PR body for manual creation
- If no issue exists → warn user, suggest creating one first
