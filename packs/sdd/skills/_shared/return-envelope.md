# Return Envelope Convention

## Purpose

Every SDD phase sub-agent MUST end its response with a structured envelope. The orchestrator parses this to decide: advance to next phase, retry, or escalate.

## Format

Place this block at the END of your phase output:

```
---envelope---
status: completed
summary: "Exploration complete. Identified 3 architectural approaches for auth feature. Recommended: JWT with refresh rotation."
artifacts_saved:
  - title: "sdd/auth-feature/explore"
    topic_key: "sdd/auth-feature/explore"
next_recommended: "propose"
risks:
  - "Current session middleware is tightly coupled — refactoring risk"
  - "No existing test coverage for auth module"
skill_resolution:
  status: injected
  skills_applied: [go-testing, security-basics]
---end-envelope---
```

## Fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `status` | YES | `completed`, `failed`, `needs_review` | Phase outcome |
| `summary` | YES | string | One paragraph executive summary |
| `artifacts_saved` | YES | list of {title, topic_key} | What was persisted to Mnemo |
| `next_recommended` | NO | phase name or empty | Suggested next phase |
| `risks` | NO | list of strings | Identified risks (omit if none) |
| `skill_resolution` | NO | {status, skills_applied} | What project standards were used |

## Status Values

| Status | Orchestrator Action |
|--------|-------------------|
| `completed` | Advance to next phase (or finish if last) |
| `failed` | Transition to failed state. User decides: retry or abort |
| `needs_review` | Stay in gate_check. Present findings to user for decision |

## Parsing Rules

The orchestrator looks for `---envelope---` and `---end-envelope---` markers. Everything between is parsed as YAML.

If no envelope is found, the orchestrator treats the entire response as a plain summary with `status: completed` (backward compatible).

## Examples

### Successful Phase
```
---envelope---
status: completed
summary: "Design document created with 3-layer architecture: API, Service, Repository."
artifacts_saved:
  - title: "sdd/auth-feature/design"
    topic_key: "sdd/auth-feature/design"
next_recommended: "tasks"
---end-envelope---
```

### Failed Phase
```
---envelope---
status: failed
summary: "Cannot proceed — specification references undefined API endpoints."
artifacts_saved: []
risks:
  - "Spec references /api/v2/users but only /api/v1/users exists"
  - "Missing database migration for new user_tokens table"
---end-envelope---
```

### Needs Review
```
---envelope---
status: needs_review
summary: "Two conflicting approaches found. Need human decision: Option A (simpler, less secure) vs Option B (complex, production-grade)."
artifacts_saved:
  - title: "sdd/auth-feature/proposal"
    topic_key: "sdd/auth-feature/proposal"
next_recommended: "specify"
risks:
  - "Option A has no token rotation — vulnerable to replay attacks"
---end-envelope---
```
