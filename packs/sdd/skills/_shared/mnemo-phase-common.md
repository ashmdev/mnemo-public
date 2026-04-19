# Mnemo SDD Phase Protocol — Shared Convention

Every SDD phase MUST follow these 4 sections in order. This ensures context survives across phases, compactions, and sessions.

## Section A: Context Recovery

Before starting any work, recover artifacts from previous phases:

1. **Search for prior artifacts:**
   ```
   mem_search(query: "sdd/{change-name}", project: "{project}", type: "architecture")
   ```
   Run ALL searches in parallel — do not serialize.

2. **Retrieve full content** for each result:
   ```
   mem_get(id: "{artifact_id}")
   ```
   Search returns 300-char previews. You MUST call `mem_get` for full untruncated content.

3. **Check .openspec.yaml** for workflow state:
   Read `openspec/changes/{change-name}/.openspec.yaml` to know which phases are completed.

4. **If compaction occurred** mid-workflow:
   - The `.openspec.yaml` file is your source of truth for current phase
   - Prior artifacts are in Mnemo memory (search by topic_key)
   - Rebuild context from persisted artifacts, then continue

## Section B: Skill Resolution

Before executing the phase, resolve project-specific standards:

1. Search for skill registry:
   ```
   mem_search(query: "skill-registry", project: "{project}", type: "config")
   ```

2. If found, identify compact rules relevant to the files being changed.

3. Apply matching compact rules during execution.

4. If no registry found, proceed with generic best practices.

## Section C: Phase Execution & Persistence

Execute the phase-specific work as defined in the phase's skill file. Then:

**MANDATORY — Persist your output:**
```
mem_save(
  title: "sdd/{change-name}/{phase-name}",
  type: "architecture",
  project: "{project}",
  topic_key: "sdd/{change-name}/{phase-name}",
  scope: "project",
  content: "{your phase output — structured markdown}"
)
```

- `topic_key` ensures upserts — re-running a phase updates the same memory, not duplicates.
- The title pattern `sdd/{change}/{phase}` enables exact-match recovery in later phases.
- Content should be self-contained — another agent should understand it without extra context.

**Update .openspec.yaml:**
Update `current_phase` and `completed_phases` after successful persistence.

## Section D: Return Envelope

Every phase MUST end with a structured return envelope:

```
---envelope---
status: completed | failed | needs_review
summary: "One paragraph executive summary of what was accomplished"
artifacts_saved:
  - title: "sdd/{change-name}/{phase-name}"
    topic_key: "sdd/{change-name}/{phase-name}"
next_recommended: "{next-phase-name or empty if last}"
risks:
  - "Description of any identified risk (omit section if none)"
skill_resolution:
  status: injected | fallback | none
  skills_applied: [skill-1, skill-2]
---end-envelope---
```

The orchestrator uses this envelope to decide whether to advance, retry, or escalate.

## Quick Reference

| Phase | Reads | Creates | Topic Key |
|-------|-------|---------|-----------|
| init | project structure | .openspec.yaml | sdd/{change}/init |
| explore | specs, code | exploration.md | sdd/{change}/explore |
| propose | exploration | proposal.md | sdd/{change}/proposal |
| specify | proposal | delta specs | sdd/{change}/spec |
| design | specs | design.md | sdd/{change}/design |
| tasks | design | tasks.md | sdd/{change}/tasks |
| implement | tasks, specs | source code | sdd/{change}/progress |
| verify | specs, code | verify-report.md | sdd/{change}/verify |
| document | all artifacts | updated docs | sdd/{change}/document |
