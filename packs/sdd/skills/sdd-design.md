# SDD: Design Phase

## Purpose

Translate the delta specification into a technical architecture. The spec says WHAT
to build; the design says HOW to build it. Define components, interfaces, data models,
and interaction sequences that will guide implementation.

**Recommended Model:** opus (architectural reasoning required)

## When to Use

After the delta spec is complete and validated. For trivial changes (single function,
simple bug fix), this phase can be lightweight. For anything touching multiple
components or introducing new abstractions, invest time here.

## Artifacts

| Action  | Path                                                      | Description                  |
|---------|-----------------------------------------------------------|------------------------------|
| Reads   | `openspec/changes/{name}/specs/{domain}/spec.md`          | Delta specifications         |
| Reads   | `openspec/changes/{name}/proposal.md`                     | Approved approach            |
| Reads   | `openspec/changes/{name}/.openspec.yaml`                  | Current phase state          |
| Creates | `openspec/changes/{name}/design.md`                       | Technical approach document  |
| Updates | `openspec/changes/{name}/.openspec.yaml`                  | Phase transition             |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase.
Read the delta specs and proposal for context.

### 2. Define Components

List every component (package, module, class, service) involved:
- **Name:** Clear, descriptive, following project conventions
- **Responsibility:** One sentence describing its single responsibility
- **Location:** File path in the project structure
- **Status:** New or modified

If you cannot describe a component's responsibility in one sentence, it does too much.

### 3. Define Interfaces

For each component, specify its public interface as real code signatures in the
project's language. Include preconditions, postconditions, and error types.
Pseudocode introduces ambiguity.

### 4. Define Data Models

For new or modified data structures: structure definition with types, relationships
to other models, lifecycle (create/update/delete), persistence strategy, and
migration path if modifying existing structures.

### 5. Describe Interaction Sequences

For each key flow from the spec, describe the sequence of component interactions
using numbered steps. Precision matters.

### 6. Address Cross-Cutting Concerns

Error propagation strategy, logging approach, configuration management,
and testing strategy for each component.

### 7. Write Design Artifact

Write to `openspec/changes/{name}/design.md`:

```markdown
# Design: {change-name}
Date: {YYYY-MM-DD}
Spec: specs/{domain}/spec.md

## Components

### {ComponentName}
- **Responsibility:** {one sentence}
- **Location:** {file path}
- **Status:** new / modified
- **Interface:**
  ```{language}
  {function signatures}
  ```

## Data Models
```{language}
{type/struct definitions}
```

## Interaction Sequences

### Flow: {flow name}
1. {step}
2. {step}
3. {step}

## Cross-Cutting Concerns
- **Error propagation:** {strategy}
- **Logging:** {what and where}
- **Testing:** {approach per component}

## Design Decisions
| Decision | Context | Alternatives | Consequence |
|----------|---------|-------------|-------------|
| {choice} | {why}   | {what else} | {impact}    |
```

### 8. Update State

Update `.openspec.yaml`: set `current_phase: design`, append `design` to `completed_phases`.
Save architecture decisions in Mnemo.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Prior architecture decisions for this area |
| Store  | End   | New design decisions and component map      |

## Validation Checklist

Before proceeding to Tasks:

- [ ] `design.md` written to `openspec/changes/{name}/`
- [ ] All components identified with clear single responsibilities
- [ ] Interfaces defined as real code signatures (not pseudocode)
- [ ] Data models specified with types, relationships, and lifecycle
- [ ] Key interaction sequences described step by step
- [ ] Cross-cutting concerns addressed (errors, logging, testing)
- [ ] Design decisions documented with context and alternatives
- [ ] Design is consistent with existing project architecture
- [ ] `.openspec.yaml` updated to reflect completed design phase

## Common Pitfalls

- **Over-abstraction:** Interfaces "for flexibility" with only one implementation.
- **Missing error paths:** Show what happens when things fail, not just when they succeed.
- **Ignoring existing architecture:** Locally elegant but globally inconsistent creates confusion.
- **Pseudocode interfaces:** Write real signatures with real types.
