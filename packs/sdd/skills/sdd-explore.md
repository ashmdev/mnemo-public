# SDD: Exploration Phase

## Purpose

Build a detailed understanding of the codebase areas relevant to the current change.
While Init gives a bird's-eye view, Explore goes deep: reading source files, tracing
data flows, and mapping dependencies that constrain or enable the solution.

**Recommended Model:** sonnet (codebase reading, no deep reasoning required)

## When to Use

After Init, when the change touches existing code. Skip only for greenfield projects
with no existing codebase to explore.

## Artifacts

| Action  | Path                                              | Description                |
|---------|---------------------------------------------------|----------------------------|
| Reads   | `openspec/specs/{domain}/spec.md`                 | Existing specifications    |
| Reads   | `openspec/changes/{name}/.openspec.yaml`          | Current phase state        |
| Creates | `openspec/changes/{name}/exploration.md`          | Exploration findings       |
| Updates | `openspec/changes/{name}/.openspec.yaml`          | Phase transition           |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `openspec/changes/{name}/.openspec.yaml` to confirm you are in the right phase.
If `current_phase` is already past `explore`, this phase was completed previously.

### 2. Identify Exploration Targets

From the Init assessment, list the files and modules that are relevant:
- Files directly mentioned in the request
- Files that implement related functionality
- Shared utilities and helpers used by those files
- Test files covering the affected code
- Configuration files that govern behavior

### 3. Read and Catalog Source Files

For each relevant file, document responsibilities, public interface, internal logic,
dependencies (imports and importers), and test coverage. Read methodically. The details
you miss here become bugs later.

### 4. Trace Data Flows

For the functionality being modified, trace the data path:
- **Entry point:** Where does data enter the system?
- **Transformations:** How is data validated, transformed, enriched?
- **Storage:** Where is data persisted and in what format?
- **Output:** How does processed data reach the user or downstream system?

### 5. Map Dependencies

Create a dependency map: upstream callers, downstream callees, shared state,
external services, and configuration sources.

### 6. Check Existing Specs

Read `openspec/specs/` for any domain specs that cover the area being changed.
Note which requirements already exist and which will need delta modifications.

### 7. Write Exploration Artifact

Write findings to `openspec/changes/{name}/exploration.md`:

```markdown
# Exploration: {change-name}
Date: {YYYY-MM-DD}

## File Inventory
| File | Responsibility | Lines | Test Coverage |
|------|---------------|-------|---------------|
| path/to/file | Handles X | 150 | Yes (unit) |

## Data Flow
entry -> step 1 -> step 2 -> output

## Dependency Map
- **Component A** depends on: B, C | depended on by: D, E

## Technical Constraints
- constraint: description and impact

## Existing Spec Coverage
- specs/{domain}/spec.md covers: REQ-1, REQ-2
- No existing spec for: {area}

## Patterns to Follow
- pattern: where used and how

## Key Observations
- insight that will influence the proposal
```

### 8. Update State

Update `.openspec.yaml`: set `current_phase: explore`, append `explore` to `completed_phases`.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Prior exploration notes for same area |
| Store  | End   | Dependency map, constraints, observations |

## Validation Checklist

Before proceeding to Propose:

- [ ] All relevant source files read (not skimmed)
- [ ] Data flow for affected functionality traced end-to-end
- [ ] Dependency map complete for affected components
- [ ] Technical constraints identified and documented
- [ ] Existing specs in `openspec/specs/` reviewed for overlap
- [ ] `exploration.md` written to `openspec/changes/{name}/`
- [ ] `.openspec.yaml` updated to reflect completed explore phase
- [ ] Findings saved to Mnemo

## Common Pitfalls

- **Reading too few files:** Missing upstream callers that will break.
- **Ignoring tests:** Existing tests are a specification of expected behavior.
- **Skipping existing specs:** Delta specs build on what already exists in `openspec/specs/`.
- **Not writing exploration.md:** Later phases lose context without the written artifact.
