# SDD: Task Decomposition Phase

## Purpose

Break the design into small, implementable tasks with clear boundaries and checkboxes.
Each task should be completable in a single focused session (under 30 minutes). The
task list becomes the execution plan and the progress tracker for implementation.

**Recommended Model:** sonnet (structured decomposition, no deep reasoning)

## When to Use

After the design is complete. Even for small features, explicit task decomposition
prevents scope drift that turns simple changes into sprawling commits.

## Artifacts

| Action  | Path                                              | Description                    |
|---------|---------------------------------------------------|--------------------------------|
| Reads   | `openspec/changes/{name}/design.md`               | Technical approach             |
| Reads   | `openspec/changes/{name}/specs/{domain}/spec.md`  | Delta specifications           |
| Reads   | `openspec/changes/{name}/.openspec.yaml`           | Current phase state            |
| Creates | `openspec/changes/{name}/tasks.md`                | Implementation checklist       |
| Updates | `openspec/changes/{name}/.openspec.yaml`           | Phase transition               |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase.
Read `design.md` and delta specs for context.

### 2. Identify Task Boundaries

Each task should:
- Do one thing (create a file, implement a function, write tests for a component)
- Be independently verifiable without completing other tasks
- Have clear inputs and outputs
- Fit in under 30 minutes (split if bigger)

### 3. Define Each Task

For every task, specify:
- **ID:** Sequential (T1, T2, T3...)
- **Title:** Action-oriented ("Implement UserRepository.Save method")
- **Spec reference:** Which requirement or design section this addresses
- **Files:** Which files to create or modify
- **Definition of done:** How to verify the task is complete
- **Model recommendation:** `sonnet` for routine work, `opus` for complex logic

### 4. Map Dependencies and Parallel Waves

State depends-on and blocks relationships. Group into execution waves:
- **Wave 1:** All tasks with no dependencies (parallel)
- **Wave 2:** Tasks depending only on Wave 1 (parallel after Wave 1)
- Continue until all tasks scheduled

### 5. Write Tasks Artifact

Write to `openspec/changes/{name}/tasks.md`:

```markdown
# Tasks: {change-name}
Date: {YYYY-MM-DD}
Design: design.md

## Checklist

- [ ] **T1: {title}** (model: sonnet)
  Spec: REQ-{ID} | Files: {list} | Depends: none | Blocks: T3
  Done: {verifiable condition}

- [ ] **T2: {title}** (model: sonnet)
  Spec: REQ-{ID} | Files: {list} | Depends: none | Blocks: T4
  Done: {verifiable condition}

- [ ] **T3: {title}** (model: opus)
  Spec: REQ-{ID} | Files: {list} | Depends: T1 | Blocks: T5
  Done: {verifiable condition}

- [ ] **T4: {title}** (model: sonnet)
  Spec: REQ-{ID} | Files: {list} | Depends: T2 | Blocks: T5
  Done: {verifiable condition}

- [ ] **T5: {title}** (model: sonnet)
  Spec: REQ-{ID} | Files: {list} | Depends: T3, T4 | Blocks: none
  Done: {verifiable condition}

## Execution Plan

| Wave | Tasks  | Parallel | Est. Time |
|------|--------|----------|-----------|
| 1    | T1, T2 | yes      | 20 min    |
| 2    | T3, T4 | yes      | 25 min    |
| 3    | T5     | no       | 15 min    |

## Dependency Graph
T1 --> T3 --> T5
T2 --> T4 --/

## Totals
- Sequential: {sum of all estimates}
- Parallel: {sum of wave estimates}
- Tasks: {count}
```

### 6. Update State

Update `.openspec.yaml`: set `current_phase: tasks`, append `tasks` to `completed_phases`.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Task patterns from previous similar features |
| Store  | End   | Task plan for reference during implementation |

## Validation Checklist

Before proceeding to Implement:

- [ ] `tasks.md` written to `openspec/changes/{name}/`
- [ ] Every design component covered by at least one task
- [ ] Every delta spec requirement traced to at least one task
- [ ] No task estimated over 30 minutes
- [ ] Dependencies explicit and minimal, no circular dependencies
- [ ] Parallel execution waves identified
- [ ] Each task has a clear, verifiable definition of done
- [ ] Model recommendation assigned to each task
- [ ] `.openspec.yaml` updated to reflect completed tasks phase

## Common Pitfalls

- **Tasks too large:** "Implement the feature" is not a task. Break it down.
- **Tasks too small:** "Add import statement" is too granular. Group logically.
- **Hidden dependencies:** Task B needs Task A's output but it is not listed.
- **Missing test tasks:** Implementation tasks without test tasks lead to untested code.
