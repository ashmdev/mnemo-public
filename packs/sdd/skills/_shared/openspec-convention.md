# OpenSpec Convention Reference

Shared reference for all SDD skills. Defines the directory structure, artifact paths,
file formats, and state tracking used throughout the SDD workflow.

## Directory Structure

```
openspec/
├── specs/{domain}/spec.md              # Source of truth (current behavior)
├── changes/{change-name}/              # One folder per active change
│   ├── .openspec.yaml                  # State tracking for compaction recovery
│   ├── exploration.md                  # Codebase findings (sdd-explore)
│   ├── proposal.md                     # Intent, scope, approach (sdd-propose)
│   ├── specs/{domain}/spec.md          # Delta specs (sdd-specify)
│   ├── design.md                       # Technical approach (sdd-design)
│   ├── tasks.md                        # Implementation checklist (sdd-tasks)
│   └── verify-report.md               # Verification results (sdd-verify)
└── changes/archive/YYYY-MM-DD-{name}/  # Completed changes (sdd-document)
```

## Artifact Ownership

| Skill          | Creates                                         | Reads                                |
|----------------|------------------------------------------------|--------------------------------------|
| sdd-init       | `openspec/`, `openspec/specs/`, config.yaml     | existing openspec/ if present        |
| sdd-explore    | `changes/{name}/exploration.md`                 | codebase, specs/                     |
| sdd-propose    | `changes/{name}/proposal.md`                    | exploration.md                       |
| sdd-specify    | `changes/{name}/specs/{domain}/spec.md`         | proposal.md, specs/                  |
| sdd-design     | `changes/{name}/design.md`                      | delta specs, proposal.md             |
| sdd-tasks      | `changes/{name}/tasks.md`                       | design.md, delta specs               |
| sdd-implement  | source code files                               | tasks.md, design.md, delta specs     |
| sdd-verify     | `changes/{name}/verify-report.md`               | delta specs, tasks.md, source code   |
| sdd-document   | `changes/archive/YYYY-MM-DD-{name}/`            | all change artifacts, specs/         |

## Delta Spec Format

Delta specs use three section headers to describe changes relative to `openspec/specs/`:

```markdown
## ADDED Requirements

### REQ-{ID}: {Title}
{Description using RFC 2119 keywords: MUST, SHALL, SHOULD, MAY}

#### Scenario: {name}
- **Given** {precondition}
- **When** {action}
- **Then** {expected outcome}

## MODIFIED Requirements

### REQ-{ID}: {Title} (was: {old title if renamed})
{Updated description. State what changed and why.}

## REMOVED Requirements

### REQ-{ID}: {Title}
{Reason for removal.}
```

Use RFC 2119 keywords consistently: MUST/SHALL for mandatory, SHOULD for recommended, MAY for optional.

## State Tracking (.openspec.yaml)

Each active change contains `.openspec.yaml` for compaction recovery:

```yaml
change: {change-name}
current_phase: design
completed_phases: [init, explore, propose, specify]
started_at: 2026-03-22T10:00:00Z
updated_at: 2026-03-22T14:30:00Z
```

When a session starts or context is compacted, read `.openspec.yaml` to resume
from the correct phase. Update it at every phase transition.

## Config File (openspec/config.yaml)

Created by sdd-init at the root of the openspec/ directory:

```yaml
project: {project-name}
default_domain: core
spec_format: gherkin
keywords: rfc2119
created_at: {ISO timestamp}
```

## Archive Convention

When sdd-document archives a completed change:

1. Merge delta specs into `openspec/specs/{domain}/spec.md` (ADDED appended, MODIFIED replaced, REMOVED deleted)
2. Move `openspec/changes/{name}/` to `openspec/changes/archive/YYYY-MM-DD-{name}/`
3. The archived folder retains all artifacts for historical reference

## Reading Artifacts

Before acting, always check for existing artifacts in the change directory.
If a prior phase produced an artifact, read it rather than re-deriving the information.
This ensures continuity across sessions and model handoffs.

## Writing Artifacts

Write artifacts as standalone markdown files. Each file MUST be self-contained
enough that a fresh agent can read it and understand the change without prior context.
Include the change name and date at the top of every artifact.
