---
name: judgment-day
description: >
  Parallel adversarial review protocol that launches two independent blind judge sub-agents
  simultaneously to review the same target, synthesizes their findings, applies fixes,
  and re-judges until both pass or escalates after 2 iterations.
  Trigger: When user says "judgment day", "judgment-day", "review adversarial", "dual review",
  "doble review", "juzgar", "que lo juzguen".
license: MIT
metadata:
  author: mnemo
  version: "1.4"
  origin: adapted from gentle-ai judgment-day v1.4
---

## When to Use

- User explicitly asks for "judgment day", "judgment-day", or equivalent trigger phrases
- After significant implementations before merging
- When high-confidence review of code, features, or architecture is needed
- When a single reviewer might miss edge cases or have blind spots
- When the cost of a production bug is higher than the cost of two review rounds

## Critical Patterns

### Pattern 0: Skill Resolution (BEFORE launching judges)

Use Mnemo's `mem_search` to resolve relevant project skills before launching any sub-agent:

1. Search for project standards: `mem_search(query: "skill-registry", project: "{project}")` then `mem_search(query: "coding standards", project: "{project}")`
2. If no registry found in memory, check filesystem: look for `.mnemorc` skills config, then `packs/*/skills/` directories
3. Identify the target files/scope -- what code will the judges review?
4. Match relevant skills by code context (file extensions/paths) and task context
5. Build a `## Project Standards (auto-resolved)` block with matching rules
6. Inject this block into BOTH Judge prompts AND the Fix Agent prompt (identical for all)

**If no registry exists**: warn the user ("No skill registry found -- judges will review without project-specific standards.") and proceed with generic review only.

### Pattern 1: Parallel Blind Review

- Launch **TWO** sub-agents via MCP tool delegation (async, parallel -- never sequential)
- Each agent receives the **same target** but works **independently**
- **Neither agent knows about the other** -- no cross-contamination
- Both use identical review criteria but may find different issues
- NEVER do the review yourself as the orchestrator -- your job is coordination only

### Pattern 2: Verdict Synthesis

The **orchestrator** (NOT a sub-agent) compares results after both judges complete:

```
Confirmed    -> found by BOTH agents          -> high confidence, fix immediately
Suspect A    -> found ONLY by Judge A         -> needs triage
Suspect B    -> found ONLY by Judge B         -> needs triage
Contradiction -> agents DISAGREE on the same thing -> flag for manual decision
```

Present findings as a structured verdict table (see Output Format).

### Pattern 3: Warning Classification

Judges MUST classify every WARNING into one of two sub-types:

```
WARNING (real)        -> Causes a bug, data loss, security hole, or incorrect behavior
                         in a realistic production scenario. Fix required.
WARNING (theoretical) -> Requires a contrived scenario, corrupted input, or conditions
                         that cannot arise through normal usage. Report but do NOT block.
```

**How to classify**: ask "Can a normal user, using the tool as intended, trigger this?" If YES -> real. If it requires a malicious manifest, renamed home dir, two clicks in <1ms, or OS-specific edge case -> theoretical.

**Theoretical warnings are reported as INFO** in the verdict table. They are NOT fixed, do NOT trigger re-judgment, and do NOT count toward the convergence threshold.

### Pattern 4: Fix and Re-judge

1. If **confirmed CRITICALs or real WARNINGs** exist -> delegate a **Fix Agent** (separate delegation)
2. After Fix Agent completes -> re-launch **both judges in parallel** (same blind protocol, fresh delegates)
3. **After 2 fix iterations**, if issues remain -> present findings to user and ASK: "Should I continue iterating?" If YES -> continue. If NO -> JUDGMENT: ESCALATED.
4. If both judges return clean -> JUDGMENT: APPROVED

### Pattern 5: Convergence Threshold

**Round 1**: Present the verdict table to the user. ASK: "These are the confirmed issues. Want me to fix them?" Only fix after user confirms. Then re-judge with full scope.

**Round 2+**: Only re-judge if there are **confirmed CRITICALs**. For anything else:
- **Real WARNINGs** (confirmed): Fix inline, do NOT re-launch judges. Report as "fixed without re-judge".
- **Theoretical WARNINGs**: Report as INFO. Do NOT fix, do NOT re-judge.
- **SUGGESTIONs**: Fix inline if trivial. Do NOT re-judge.

**APPROVED criteria after Round 1**: 0 confirmed CRITICALs + 0 confirmed real WARNINGs = APPROVED.

### Pattern 6: Memory Feedback (Mnemo-specific)

After every completed judgment (APPROVED or ESCALATED), save findings as pattern memories:

```
For each confirmed finding:
  mem_save(
    type: "pattern",
    title: "judgment-day: {finding category} in {file/component}",
    content: "{description of the issue and fix applied}",
    project: "{project}",
    topic_key: "pattern/judgment-day/{category}"
  )
```

This enables Mnemo to learn from reviews across sessions -- future judges can search for known patterns.

---

## Decision Tree

```
User asks for "judgment day"
|
+-- Target is specific files/feature/component?
|   +-- YES -> continue
|   +-- NO -> ask user to specify scope before proceeding
|
v
Resolve skills (Pattern 0): mem_search -> match by code + task context -> build Project Standards
v
Launch Judge A + Judge B in parallel (MCP tool delegation, async)
v
Wait for both to complete
v
Synthesize verdict
|
+-- No issues found?
|   +-- JUDGMENT: APPROVED (stop here, save to memory)
|
+-- Issues found (confirmed, suspect, contradictions)?
|   +-- Present verdict table to user
|       v
|       ASK: "Fix confirmed issues?"
|       +-- User says YES -> Delegate Fix Agent with confirmed issues
|       +-- User says NO -> JUDGMENT: ESCALATED (save to memory)
|       +-- User gives specific feedback -> adjust fix list
|       v
|       Wait for Fix Agent to complete
|       v
|       Re-launch Judge A + Judge B in parallel (Round 2)
|       v
|       Synthesize verdict
|       +-- Clean -> JUDGMENT: APPROVED (save to memory)
|       +-- Still issues -> Fix Agent again (Round 3)
|           v
|           Re-launch judges (Round 3)
|           +-- Clean -> JUDGMENT: APPROVED
|           +-- Still issues -> ASK USER: "Continue iterating?"
|               +-- YES -> repeat
|               +-- NO -> JUDGMENT: ESCALATED
```

---

## Sub-Agent Prompt Templates

### Judge Prompt (identical for Judge A and Judge B)

```
You are an adversarial code reviewer. Your ONLY job is to find problems.

## Target
{describe target: files, feature, architecture, component}

{if compact rules were resolved, inject:}
## Project Standards (auto-resolved)
{matching compact rules from mem_search}

## Review Criteria
- Correctness: Does the code do what it claims? Logical errors?
- Edge cases: What inputs or states aren't handled?
- Error handling: Are errors caught, propagated, and logged properly?
- Performance: N+1 queries, inefficient loops, unnecessary allocations?
- Security: Injection risks, exposed secrets, improper auth checks?
- Naming & conventions: Does it follow Project Standards?
{custom criteria if user provided}

## Return Format
Each finding:
- Severity: CRITICAL | WARNING (real) | WARNING (theoretical) | SUGGESTION
- File: path/to/file.ext (line N if applicable)
- Description: What is wrong and why
- Suggested fix: one-line description

WARNING classification: "Can a normal user trigger this?"
- YES -> WARNING (real)
- NO -> WARNING (theoretical)

If NO issues: VERDICT: CLEAN

Be thorough and adversarial. Assume bugs until proven otherwise.
```

### Fix Agent Prompt

```
You are a surgical fix agent. Fix ONLY the confirmed issues listed below.

## Confirmed Issues
{paste confirmed findings table}

{if standards resolved:}
## Project Standards (auto-resolved)
{matching rules}

## Instructions
- Fix ONLY confirmed issues
- Do NOT refactor beyond the fix
- Scope rule: If fixing a pattern, search ALL files for the same pattern
- After each fix, note: file, line, what was done
```

---

## Output Format

```markdown
## Judgment Day -- {target}

### Round {N} -- Verdict

| Finding | Judge A | Judge B | Severity | Status |
|---------|---------|---------|----------|--------|
| Missing null check in auth.go:42 | Y | Y | CRITICAL | Confirmed |
| Race condition in worker.go:88 | Y | N | WARNING (real) | Suspect (A) |
| Windows edge case | N | Y | WARNING (theoretical) | INFO |

**Confirmed issues**: N CRITICAL, M WARNING (real)
**Suspect issues**: ...
**Contradictions**: ...

### Fixes Applied (Round {N})
- `auth.go:42` -- Added nil check

### Round {N+1} -- Re-judgment
- Judge A: PASS
- Judge B: PASS

### JUDGMENT: APPROVED
Both judges pass clean.
```

---

## Rules

- The **orchestrator NEVER reviews code itself** -- only launches judges, reads results, synthesizes
- Judges MUST be launched in **parallel** (never sequential)
- The **Fix Agent is a separate delegation** -- never reuse a judge as fixer
- **After 2 fix iterations**, ASK user before continuing -- never auto-escalate
- Always wait for BOTH judges before synthesizing -- no partial verdicts
- Suspect findings reported but NOT auto-fixed -- triage with user
- **MUST NOT** declare APPROVED until 0 CRITICALs + 0 confirmed real WARNINGs
- **MUST NOT** push/commit after fixes until re-judgment completes
- Save pattern memories after every terminal state (Pattern 6)

---

## Language

- **Spanish input**: "Juicio iniciado", "Los jueces trabajan en paralelo...", "Juicio terminado -- Aprobado"
- **English input**: "Judgment initiated", "Both judges working in parallel...", "Judgment complete -- Approved"

---

## Examples

```
User: judgment day on the auth middleware
-> Resolve skills via mem_search
-> Launch Judge A + Judge B with auth middleware scope
-> Both return findings
-> Synthesize: 1 CRITICAL (null check), 1 WARNING real (error swallowed)
-> Present to user, ask to fix
-> User confirms
-> Fix Agent applies 2 fixes
-> Re-launch judges
-> Both CLEAN
-> JUDGMENT: APPROVED
-> Save 2 pattern memories
```
