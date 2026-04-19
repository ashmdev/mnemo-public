# Core: Roadmap Keeper

## Purpose

Keep `docs/ROADMAP_2026.md` alive, accurate, and executable. The roadmap is the single
source of truth for 2026 delivery — this skill is the protocol for reading it, acting on
it, updating it, and preventing drift between plan, code, and `BACKLOG.md`. A stale
roadmap is worse than no roadmap; this skill exists so that never happens.

## When to Use

- Start of every session that touches feature work.
- After merging any PR that closes or advances a roadmap task.
- Weekly on Monday (reconciliation pass).
- Any time the user asks "what's next", "what are we working on", "roadmap status", or
  asks to plan new work.
- Before starting a task: to verify the task's ID, effort, and deps are still valid.
- Before creating a new task proposal: to find the right week slot and generate the ID.

## Instructions

### 1. Read before you write

Open `docs/ROADMAP_2026.md`. Never edit without reading the current state — the document
is actively maintained and edits based on stale assumptions break IDs, dependencies, or
change-log coherence. If any other doc (`ROADMAP.md` in archive, old strategic plan,
implementation plan) disagrees with the canonical roadmap, the canonical roadmap wins.
Never copy forward plans from archived documents.

### 2. Pick the current week

Week 1 anchor is **2026-04-13**. Compute today's week:

```
weeks_elapsed = floor((today - 2026-04-13) / 7 days)
current_week  = weeks_elapsed + 1
```

Clamp to [1, 52]. Map to the quarter using §4 Calendar in the roadmap. All "what's next"
questions should start from the current week's table.

### 3. Status transitions

Checkbox states are the ground truth. Allowed transitions:

```
[ ]  open          →  [~]  in progress  →  [x]  done
[ ]  open          →  [-]  cancelled
[~]  in progress   →  [ ]  open           (revert, rare)
```

Rules:
- Flip `[ ]` → `[~]` the moment work starts. Not the moment a PR is opened.
- Flip `[~]` → `[x]` only when the task is merged to `main` AND covered by a test or
  verification step. Partial work stays `[~]`.
- `[-]` (cancelled) requires a change-log entry with the reason.
- Never delete a task to "cancel" it. Always mark `[-]`.
- Never reuse a cancelled ID for a different task.

### 4. Adding a new task

1. Decide the target week (usually the current week or the next free slot).
2. Generate the ID: `T-Q{q}W{ww}-{nn}` where `nn` is the next free sequence in that
   week's table.
3. Fill all six columns: ID · Task · Effort · Impact · Status · Deps.
4. If the task depends on another task, list the dep ID. If the dep isn't merged,
   the new task cannot be marked `[~]`.
5. Append a row to §11 Change Log with date, ID, and one-line description.

### 5. Reconciliation pass (weekly, Monday)

Run through this checklist. Any mismatch is a bug in the roadmap or the code — fix it.

- [ ] Every task marked `[~]` has an open PR or a commit on a feature branch within the
      last 7 days. If not → revert to `[ ]` and note in change log.
- [ ] Every task marked `[x]` links to a merged commit or PR in the BACKLOG.md log.
      If not → demote to `[~]` pending evidence.
- [ ] `BACKLOG.md` §🔴 Bloqueantes matches the roadmap's `T-Q2W01-05`/`T-Q2W01-06` state.
      If one moved, move the other.
- [ ] Current snapshot (§3) numbers match reality: skill count = `ls packs/*/skills/ | wc -l`,
      pack count = `ls packs/ | wc -l`, MCP tool count = count in `internal/transport/mcp/`.
      If stale → update the table.
- [ ] For every `[x]` task shipped in the past week, confirm a `BACKLOG.md` §✅ row
      exists with a commit SHA. If missing → add it.
- [ ] For every open task whose week is past, either advance its ID to a future week
      (with a change-log note) or mark `[-]` cancelled.

### 6. End-of-quarter closeout

At the retrospective task (`T-Q2W07-04`, `T-Q3W19-04`, `T-Q4W33-02`):

1. Count tasks shipped vs planned for the quarter. Publish ratio.
2. Every unshipped task must be either rolled forward (new ID in next quarter) or
   cancelled. No zombies.
3. Update §6 Current Snapshot scores based on quarter-end state.
4. Update §2 Business / Technical Metrics with measured values.
5. Draft next quarter's exit criteria. Commit draft as a change-log entry for review.

### 7. Execute next task (the completion protocol)

This is the flow to actually *advance* the roadmap, not just maintain it. Run it when
the user says "work on the next task", "continue the roadmap", "what's next", or at the
start of any session once the keeper has established current state.

**Step 1 — Pick the task**

1. Compute current week (§2).
2. Scan the current week's table for open `[ ]` tasks.
3. If the week has multiple open tasks, rank by this tuple:
   - 🚫 blocker markers first (B1/B2 equivalents)
   - 🌟 North Star next
   - deps satisfied (every dep is `[x]`)
   - highest impact
   - lowest effort within same impact tier
4. If the current week is empty, roll to the next week with open tasks. Note the roll
   in the change log.

**Step 2 — Confirm before starting**

Before flipping `[ ]` → `[~]`, surface the task to the user:

```
Next task: T-Q2W01-07 · Publish competitive post "Mnemo vs Engram vs SuperLocalMemory vs Mem0"
Effort: 1d · Impact: 5 (🌟) · Deps: none · Files: claudedocs/launch-posts.md or new blog/ entry
Proceed? [y/n]
```

Wait for confirmation. Do not start work without it — user may want to swap order.

**Step 3 — Flip to in-progress**

On confirmation, update the checkbox `[ ]` → `[~]` in the current roadmap file in a
single commit, message format:

```
roadmap(start): T-Q2W01-07 competitive post
```

Do not batch multiple `[~]` flips — one task at a time. Never have two `[~]` tasks
owned by the same session.

**Step 4 — Execute**

Do the work per task description. For each task type:

| Task type | Execution discipline |
|---|---|
| **Code change** | Read surrounding code first. Write tests. Build + test green before commit. |
| **Doc/spec** | Follow repo conventions. Cross-link from index. Prose tight, no filler. |
| **Infra/setup** | Confirm destructive steps with user. Document in `BACKLOG.md` log. |
| **Decision/ADR** | Draft `docs/ADR-NNN-<slug>.md`. Link from §7 of roadmap. Do not flip `[x]` until ADR is merged. |
| **Marketing/content** | Respect voice/tone of existing posts. Cross-link back to roadmap task ID. |

**Step 5 — Complete**

A task is `[x]` only when **all** of the following hold:

- Work is merged to `main` (or the active feature branch is a PR with green CI).
- If code: tests exist and pass. If doc: rendered markdown reviewed.
- Success criteria in the task description are met verbatim (no "mostly done").
- `BACKLOG.md` §✅ has a new row: task ID, short description, commit SHA, date.
- For 🚫 blockers: the blocker condition no longer occurs in a fresh run.

On all five: flip `[~]` → `[x]`, commit message format:

```
roadmap(done): T-Q2W01-07 competitive post published
```

**Step 6 — Cascade**

After `[x]`, scan the roadmap for tasks whose deps include this ID. If any are now
fully-unblocked, surface them to the user as the next candidate without auto-starting.
This is the mechanism that keeps dependency chains moving.

**Step 7 — If blocked**

If a task cannot complete within its week:

- Keep `[~]`.
- Add a one-line blocker note in §11 change log.
- If blocker persists > 14 days: revert to `[ ]`, annotate reason, roll to a future
  week or mark `[-]` cancelled.
- Never silently leave `[~]` indefinitely. Zombie tasks are the failure mode this skill
  exists to prevent.

### 8. When to escalate

Some edits require more than a mechanical update — escalate to the user first:

- A North Star 🌟 task slips more than one week.
- A blocker (B1/B2 equivalents) is discovered and no current-week slot is free.
- Scope of a 🆕 IA-2026 task changes (these encode strategic bets — changes need a
  conversation, not a silent edit).
- A Technology Decision in §7 of the roadmap needs revision. Don't rewrite it —
  open an ADR (`docs/ADR-NNN-<slug>.md`) and link it from the change log.

### 9. Guardrails

- **Never write forward commitments in `BACKLOG.md`.** That document is a past-tense
  log. All "we will" statements live in the roadmap.
- **Never widen the scope of a task silently.** If a task grows, either split it into
  additional IDs or update effort + change log.
- **Never let two documents claim to be canonical.** If a new strategic doc is needed,
  it supersedes and archives the existing one — per the same archiving pattern used on
  2026-04-17.
- **Never invent metrics.** TTFMR is measured (once `T-Q2W05-07` ships), not estimated.
  Until instrumented, surface the caveat.

## Success Criteria

- A new contributor can open `docs/ROADMAP_2026.md`, identify the current week, pick an
  open task, and start work without asking clarifying questions.
- `BACKLOG.md` and the roadmap agree on every shipped item within 24 hours of merge.
- No task sits in `[~]` for more than 14 days without progress or a change-log update.
- Every quarter's retrospective reports a shipped-vs-planned ratio ≥ 70%.

## Anti-patterns this skill prevents

- Two roadmap documents, both claiming canonical (as happened before 2026-04-17).
- Tasks renumbered mid-flight (IDs must be stable once created).
- Ambiguous "W0 vs W1" off-by-ones.
- Silent scope creep.
- `BACKLOG.md` used for forward planning (it is past-tense only).
- Retrospectives that never happen (they are roadmap tasks with IDs, not optional).
