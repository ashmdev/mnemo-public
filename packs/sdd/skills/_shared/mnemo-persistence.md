# Mnemo SDD Persistence Convention

## Naming Pattern

All SDD artifacts use deterministic naming for reliable recovery:

| Field | Pattern | Example |
|-------|---------|---------|
| title | `sdd/{change-name}/{artifact-type}` | `sdd/auth-feature/proposal` |
| topic_key | same as title | `sdd/auth-feature/proposal` |
| type | `architecture` | always `architecture` for SDD artifacts |

**Artifact types by phase:**
- init, explore, proposal, spec, design, tasks, progress, verify-report, document, archive

## Two-Step Recovery

Mnemo search returns previews (300 chars). Full content requires a second call:

1. **Search** (group ALL searches, run in parallel):
   ```
   mem_search(query: "sdd/{change-name}", project: "{project}")
   ```
   Returns: IDs + 300-char previews for each artifact.

2. **Retrieve** (group ALL retrievals, run in parallel):
   ```
   mem_get(id: "{id-from-search}")
   ```
   Returns: Full untruncated content.

**Never skip step 2.** Previews are insufficient for phase execution.

## Compaction Recovery

If context is compacted mid-workflow:

1. Read `.openspec.yaml` for current phase and completed phases
2. `mem_search(query: "sdd/{change-name}")` to find all persisted artifacts
3. `mem_get()` for each artifact needed by the current phase
4. Rebuild working context from artifacts
5. Continue from current phase

**This works because every phase persists its output via topic_key.** Even after compaction, the knowledge exists in Mnemo memory.

## Upsert Behavior

Using `topic_key` means:
- First save: creates new memory
- Subsequent saves with same topic_key: soft-deletes old, creates new (revision_count incremented)
- Re-running a phase safely updates its artifact without creating duplicates

## Scope Rules

| Scope | When |
|-------|------|
| `project` | Default for all SDD artifacts (shared with team) |
| `personal` | Developer notes, preferences, not relevant to team |
| `team` | Cross-project architectural patterns discovered during SDD |
