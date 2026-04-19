# SDD Workflow: Specification-Driven Development

A structured workflow where AI agents develop software through sequential specification
phases. Each phase produces concrete OpenSpec artifacts that feed the next, replacing
ad-hoc coding with disciplined, traceable development.

## Principles

- **Specs before code.** Every line of implementation traces back to a specification.
- **Phase gates.** Each phase has validation criteria that must pass before proceeding.
- **Memory continuity.** Mnemo stores decisions, learnings, and context across phases.
- **Right model for the job.** Lightweight models handle routine work; reasoning models tackle design.
- **Artifact chain.** Every phase reads from prior artifacts and writes its own.
- **Compaction recovery.** `.openspec.yaml` tracks state so sessions can resume after context loss.

---

## Artifact Flow

```
proposal.md --> specs/{domain}/spec.md --> design.md --> tasks.md --> [code] --> verify-report.md --> archive/
```

Each phase reads and writes specific OpenSpec artifacts:

| Phase     | Reads                          | Creates                                        |
|-----------|--------------------------------|------------------------------------------------|
| Init      | existing openspec/ (if any)    | openspec/, config.yaml, .openspec.yaml         |
| Explore   | codebase, specs/               | exploration.md                                 |
| Propose   | exploration.md                 | proposal.md                                    |
| Specify   | proposal.md, specs/            | changes/{name}/specs/{domain}/spec.md          |
| Design    | delta specs, proposal.md       | design.md                                      |
| Tasks     | design.md, delta specs         | tasks.md                                       |
| Implement | tasks.md, design.md, specs     | source code, checks off tasks.md               |
| Verify    | delta specs, tasks.md, code    | verify-report.md                               |
| Document  | all artifacts, specs/          | archive/YYYY-MM-DD-{name}/, merged main specs  |

All artifacts live under `openspec/changes/{change-name}/` until archived.

---

## Phase: Init

**Model:** sonnet (lightweight, fast)
**Skill:** `sdd-init`
**Creates:** `openspec/` scaffold, `openspec/changes/{name}/`, `.openspec.yaml`, `config.yaml`

Establish the OpenSpec directory structure, load project context from Mnemo, scan the
codebase for patterns, and assess the scope of the requested work. If `openspec/`
already exists, read existing specs and active changes instead of recreating.

**Gate:** OpenSpec structure exists, change directory created, scope assessed.

---

## Phase: Explore

**Model:** sonnet (lightweight, fast)
**Skill:** `sdd-explore`
**Reads:** codebase, `openspec/specs/` | **Creates:** `exploration.md`

Deep dive into relevant codebase areas. Read source files, trace data flows, map
dependencies, and document technical constraints. Check existing specs in
`openspec/specs/` for overlap with the current change.

**Gate:** All relevant files read, dependency map complete, exploration.md written.

---

## Phase: Propose

**Model:** opus (strong reasoning)
**Skill:** `sdd-propose`
**Reads:** `exploration.md` | **Creates:** `proposal.md`

Generate multiple implementation approaches and evaluate trade-offs. Recommend one
approach with clear justification. Wait for user approval before proceeding.

**Gate:** 2+ approaches compared, one recommended, user approved, proposal.md written.

---

## Phase: Specify

**Model:** opus (precision and completeness)
**Skill:** `sdd-specify`
**Reads:** `proposal.md`, `openspec/specs/` | **Creates:** `specs/{domain}/spec.md`

Write delta specs using the OpenSpec format: ADDED/MODIFIED/REMOVED sections with
RFC 2119 keywords and Given/When/Then scenarios. Define API contracts, edge cases,
and error handling.

**Gate:** Delta spec written, all requirements have scenarios, no ambiguous language.

---

## Phase: Design

**Model:** opus (architectural reasoning)
**Skill:** `sdd-design`
**Reads:** delta specs, `proposal.md` | **Creates:** `design.md`

Translate the delta spec into technical architecture. Define components, interfaces,
data models, and interaction sequences. Document design decisions with rationale.

**Gate:** Components defined, interfaces as real code signatures, design.md written.

---

## Phase: Tasks

**Model:** sonnet (structured decomposition)
**Skill:** `sdd-tasks`
**Reads:** `design.md`, delta specs | **Creates:** `tasks.md`

Break the design into implementable tasks with checkboxes, each under 30 minutes.
Map dependencies, identify parallel waves, assign model recommendations.

**Gate:** All design components covered, tasks have checkboxes, waves identified.

---

## Phase: Implement

**Model:** codex-5.4 or sonnet per task (opus for complex tasks)
**Skill:** `sdd-implement`
**Reads:** `tasks.md`, `design.md`, delta specs | **Updates:** `tasks.md` (checks off tasks)

Execute each task following the wave plan. For each task: read spec, implement,
self-review, check off in tasks.md. Document deviations and save learnings.

**Gate:** All tasks checked off, code compiles, deviations documented.

---

## Phase: Verify

**Model:** codex-5.4 or opus (critical evaluation)
**Skill:** `sdd-verify`
**Reads:** delta specs, `tasks.md`, source code | **Creates:** `verify-report.md`

Validate implementation against every delta spec requirement. Run existing tests,
write new tests, check edge cases, run static analysis. Report discrepancies.

**Gate:** All requirements verified, tests pass, verify-report.md written.

---

## Phase: Document

**Model:** sonnet (clear writing)
**Skill:** `sdd-document`
**Reads:** all artifacts, `openspec/specs/` | **Creates:** `archive/YYYY-MM-DD-{name}/`

Merge delta specs into main specs. Update API docs, README, inline docs. Create
changelog entry. Archive the change folder. Store session summary in Mnemo.

**Gate:** Deltas merged into main specs, change archived, documentation updated.

---

## Phase Flow

```
Init --> Explore --> Propose --> Specify --> Design --> Tasks --> Implement --> Verify --> Document
  |                    |                                           |              |           |
  v                    v                                           v              v           v
[create           [save            [save               [save        [save    [merge deltas
 openspec/]        decision]        learnings]          learnings]   bugs]    into specs/,
                                                                              archive]
```

## State Tracking

Every phase updates `openspec/changes/{name}/.openspec.yaml`:

```yaml
change: {change-name}
current_phase: {phase}
completed_phases: [init, explore, propose, ...]
started_at: {ISO timestamp}
updated_at: {ISO timestamp}
```

When a session starts or context compacts, read `.openspec.yaml` to resume correctly.

## Re-entry Points

Not every change requires all 9 phases. Use judgment:

- **Bug fix:** Init -> Explore -> Implement -> Verify
- **Small feature:** Init -> Explore -> Specify -> Implement -> Verify -> Document
- **Refactor:** Init -> Explore -> Design -> Tasks -> Implement -> Verify
- **Documentation only:** Init -> Document

The workflow adapts to scope. Phases exist to prevent skipping critical thinking,
not to add bureaucracy.

## OpenSpec Convention

See `skills/_shared/openspec-convention.md` for the full reference on directory
structure, artifact ownership, delta spec format, and archive conventions.
