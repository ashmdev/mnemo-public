# SDD: Implementation Phase

## Purpose

Execute the task plan, producing working code that satisfies the delta specification.
Each task follows a disciplined loop: read the spec, implement, self-review, check off
the task. This phase is where the planning pays off or where shortcuts reveal themselves.

**Recommended Model:** codex-5.4 or sonnet (fast code generation)

## When to Use

After the task list is finalized. Implementation without a task plan is just typing.

## Artifacts

| Action  | Path                                                      | Description                 |
|---------|-----------------------------------------------------------|-----------------------------|
| Reads   | `openspec/changes/{name}/tasks.md`                        | Implementation checklist    |
| Reads   | `openspec/changes/{name}/design.md`                       | Technical approach          |
| Reads   | `openspec/changes/{name}/specs/{domain}/spec.md`          | Delta specifications        |
| Reads   | `openspec/changes/{name}/.openspec.yaml`                  | Current phase state         |
| Updates | `openspec/changes/{name}/tasks.md`                        | Checks off completed tasks  |
| Updates | `openspec/changes/{name}/.openspec.yaml`                  | Phase transition            |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase.
Read `tasks.md` to identify which tasks are checked off and which remain.
If resuming after compaction, `.openspec.yaml` tells you where you left off,
and the checkbox state in `tasks.md` shows exact progress.

### 2. Load Reference Documents

Load the delta specs and design document for reference. Keep them accessible
throughout implementation; do not work from memory alone.

### 3. Execute Tasks by Wave

Follow the execution plan from `tasks.md`:

**For each wave:** Start all independent tasks. Wait for all to complete before
starting the next wave.

**For each task:**

#### a. Read the Spec
Open the delta spec section referenced by the task. Re-read the relevant
requirement and its Given/When/Then scenarios. Confirm what "done" means.

#### b. Implement
Write code following the design exactly. Follow project conventions from Init.
Use the interfaces defined in design.md. Handle all error cases from the spec.

#### c. Self-Review
Before checking off: Does implementation match the spec? Does it follow the
design interfaces? Are all error cases handled? Does it follow project conventions?

#### d. Check Off the Task
Edit `tasks.md` to mark the task complete:
```markdown
- [x] **T1: {title}** (model: sonnet)
```

### 4. Handle Blockers

- **Spec gap:** Document what is missing, propose reasonable behavior, note it for Verify.
- **Design conflict:** If the design does not work, document why, adjust minimally.
- **Dependency issue:** Flag and move to the next independent task.

Every deviation MUST be documented. Silent deviations look like bugs during Verify.

### 5. Save Learnings

For anything unexpected:
```
mnemo store --project <project> --scope learning \
  --key <task-id>-learning --content "<what happened and why>"
```

### 6. Update State

Update `.openspec.yaml`: set `current_phase: implement`, append `implement` to
`completed_phases` when all tasks are complete.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Per task | Relevant spec and design sections |
| Store  | Per task | Learnings and surprises           |
| Store  | End      | Implementation summary            |

## Validation Checklist

Before proceeding to Verify:

- [ ] All tasks in `tasks.md` checked off (or explicitly blocked with reason)
- [ ] Each task self-reviewed against its spec section
- [ ] Code compiles and passes syntax/type checking
- [ ] All deviations from spec or design documented
- [ ] Learnings saved to Mnemo
- [ ] No TODO comments left in code for core functionality
- [ ] `tasks.md` reflects actual completion state
- [ ] `.openspec.yaml` updated to reflect completed implement phase

## Common Pitfalls

- **Skipping self-review:** "It compiles, ship it" leads to spec violations caught late.
- **Silent deviations:** Changing the design without documenting it.
- **Gold-plating:** Adding features not in the spec. Improvements get their own SDD cycle.
- **Not checking off tasks:** Progress tracking breaks when `tasks.md` is stale.
- **Ignoring learnings:** Surprises not recorded will hit the next person working here.
