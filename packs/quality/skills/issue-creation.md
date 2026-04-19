# Quality: Issue Creation

## Purpose

Create well-structured GitHub/GitLab issues with proper templates, labels, and context.
Good issues accelerate triage, reduce back-and-forth, and create a searchable history.
Mnemo tracks created issues as memories so the team has full context across sessions.

## When to Use

- User says "create issue", "file a bug", "open ticket", "crear issue", "reportar bug"
- After discovering a bug during code review or testing
- When planning new features from specs or discussions
- After Judgment Day identifies issues that need tracking

## Instructions

### 1. Determine Issue Type

| Type | Template | Label |
|------|----------|-------|
| Bug | Bug report with repro steps | `bug`, severity label |
| Feature | Feature request with use case | `enhancement` |
| Task | Work item with acceptance criteria | `task` |
| Chore | Maintenance with rationale | `chore` |

### 2. Search for Context

Before creating, check Mnemo for related knowledge:
```
mem_search(query: "{issue topic}", project: "{project}")
```

Include relevant findings in the issue body (links to prior decisions, related bugs).

### 3. Bug Report Template

```markdown
## Description
[Clear one-sentence summary of the bug]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- OS: [e.g., macOS 14.5]
- Version: [e.g., v1.2.3]
- Browser/Runtime: [if applicable]

## Additional Context
[Screenshots, logs, related issues, Mnemo memory references]
```

### 4. Feature Request Template

```markdown
## Problem Statement
[What user problem does this solve? Who is affected?]

## Proposed Solution
[High-level description of the feature]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Alternatives Considered
[Other approaches evaluated and why they were rejected]

## Additional Context
[Mockups, prior discussions, related Mnemo decisions]
```

### 5. Label System

Apply labels systematically:

| Category | Labels |
|----------|--------|
| Type | `bug`, `enhancement`, `task`, `chore` |
| Severity | `critical`, `high`, `medium`, `low` |
| Area | `frontend`, `backend`, `api`, `infra`, `docs` |
| Status | `needs-triage`, `confirmed`, `in-progress` |

### 6. Save to Memory

After creating the issue:
```
mem_save(
  title: "Issue #{number}: {title}",
  type: "discovery",
  project: "{project}",
  topic_key: "issues/{issue-number}",
  content: "## Issue\n{title}\n## Type\n{bug/feature}\n## Link\n{url}\n## Context\n{why created}"
)
```

### 7. Approval Gate

Before submitting the issue, present it to the user for review:
- Show the full issue body formatted
- Confirm labels and assignees
- Wait for explicit approval before creating

NEVER create issues without user confirmation.

## Graceful Degradation

- If Mnemo unavailable → create issue without memory context or saving
- If GitHub/GitLab API unavailable → output issue body for manual creation
