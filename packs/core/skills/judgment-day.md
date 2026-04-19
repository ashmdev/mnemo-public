# Core: Judgment Day — Parallel Adversarial Review

## Purpose

Maximize defect detection by launching two independent blind reviewers in parallel,
synthesizing their findings, applying fixes, and re-judging until both pass. Two blind
judges find more than one because they approach from different angles with no cross-contamination.

## When to Use

- User says "judgment day", "dual review", "adversarial review", "doble review", "juzgar"
- After significant implementations before merging
- When the cost of a production bug exceeds the cost of two review rounds
- When a single reviewer might miss edge cases or have blind spots
- Before releasing features to production

## When NOT to Use

- Trivial one-line changes (regular code review is sufficient)
- Documentation-only changes
- When rapid iteration matters more than thoroughness

## Instructions

### 0. Pre-Flight: Resolve Project Standards

Before launching judges, gather project-specific standards:

1. Search Mnemo for the skill registry:
   ```
   mem_search(query: "skill-registry", project: "{project}", type: "config")
   ```
2. Fallback: read `.mnemo/skill-registry.md` from project root
3. Identify target files/scope — what code will the judges review?
4. Match relevant skills from the registry's Compact Rules by:
   - **Code context**: file extensions (`.tsx` → react, typescript; `.go` → go patterns)
   - **Task context**: "review code" → framework/language skills
5. Build a `## Project Standards (auto-resolved)` block with matching compact rules
6. Inject this block into BOTH Judge prompts AND the Fix Agent prompt (identical for all)

If no registry exists, warn the user and proceed with generic review.

### 1. Search Historical Context

Before launching judges, search Mnemo for prior knowledge about the target:
```
mem_search(query: "{files being reviewed}", project: "{project}", type: "bugfix")
mem_search(query: "{module/feature name}", project: "{project}", type: "pattern")
```

Include relevant historical findings in the judge prompt as:
```
## Known Issues in These Files (from team memory)
- [list prior bugs, patterns, discoveries]
```

This prevents re-discovering known issues and focuses judges on NEW problems.

### 2. Launch Parallel Blind Review

Launch TWO sub-agents via `Agent` tool (parallel — never sequential):

**Judge A prompt:**
```
You are JUDGE A in an adversarial code review. You are reviewing independently.
You do NOT know about any other reviewer. Be thorough and critical.

{## Project Standards (auto-resolved)}
{## Known Issues from memory}

Review the following code changes for:
1. Correctness (logic errors, boundary conditions, null safety)
2. Security (injection, auth bypass, data exposure)
3. Performance (N+1 queries, memory leaks, O(n²) algorithms)
4. Maintainability (complexity, naming, abstractions)
5. Test coverage (missing tests, weak assertions, untested paths)

Target: {files/scope}

For each finding, classify severity: CRITICAL | HIGH | MEDIUM | LOW
Output as structured verdict table.
```

**Judge B prompt:** (identical target, same standards, different agent)

**Rules:**
- Neither judge knows about the other — no cross-contamination
- Both receive identical review criteria and project standards
- NEVER do the review yourself — your job is COORDINATION ONLY

### 3. Synthesize Verdicts

After both judges return, compare results as the orchestrator:

| Category | Meaning | Action |
|----------|---------|--------|
| **Confirmed** | Found by BOTH judges | Fix immediately (high confidence) |
| **Suspect A** | Found ONLY by Judge A | Triage — likely real but needs verification |
| **Suspect B** | Found ONLY by Judge B | Triage — likely real but needs verification |
| **Contradiction** | Judges DISAGREE on the same thing | Flag for manual decision |

Present findings as a structured verdict table:

```markdown
## Judgment Day Verdict — Round {N}

### Confirmed Issues (both judges agree)
| # | Severity | File | Description | Judge A | Judge B |
|---|----------|------|-------------|---------|---------|

### Suspect Issues (single judge)
| # | Severity | File | Description | Found By | Confidence |
|---|----------|------|-------------|----------|------------|

### Contradictions (judges disagree)
| # | Topic | Judge A Position | Judge B Position | Resolution |
|---|-------|-----------------|-----------------|------------|
```

### 4. Fix Agent

If there are CONFIRMED or high-confidence SUSPECT issues:

1. Launch a Fix Agent via `Agent` tool with:
   - All confirmed issues
   - High-confidence suspect issues
   - Project standards block (same as judges received)
2. Fix Agent applies changes and reports what was fixed
3. Fix Agent does NOT judge — only fixes

### 5. Re-Judge (Max 2 Iterations)

After fixes are applied:
1. Re-launch BOTH judges on the fixed code (same parallel blind pattern)
2. If both judges pass (no CRITICAL/HIGH findings) → **VERDICT: PASSED**
3. If issues remain after 2 iterations → **ESCALATE** to user with remaining findings

### 6. Save Learnings to Memory

After review completes, automatically save valuable findings:

```
# For each CONFIRMED bug found:
mem_save(
  title: "Bug: {brief description}",
  type: "bugfix",
  project: "{project}",
  topic_key: "{module}/{issue-type}",
  content: "## What\n{description}\n## Where\n{file:line}\n## Root Cause\n{why}\n## Fix\n{how}"
)

# For patterns discovered during review:
mem_save(
  title: "Pattern: {brief description}",
  type: "pattern",
  project: "{project}",
  content: "## Pattern\n{description}\n## Examples\n{files}\n## Rule\n{what to do/avoid}"
)
```

If team sync is enabled, use `scope: "project"` so the entire team learns.

### 7. Output Format

Final report after all rounds:

```markdown
## Judgment Day Report

**Target**: {files reviewed}
**Rounds**: {1 or 2}
**Verdict**: PASSED | ESCALATED

### Summary
- Issues found: {N} (Confirmed: {X}, Suspect: {Y}, Contradictions: {Z})
- Issues fixed: {N}
- Remaining: {N} (if escalated)

### Memories Saved
- {N} bugfixes saved to Mnemo
- {N} patterns saved to Mnemo
{if team sync} - Synced to team: {team_name}

### Detailed Findings
{verdict table from Step 3}
```

## Graceful Degradation

- If Mnemo memory is unavailable → skip Steps 1 and 6, proceed with review
- If skill registry not found → warn user, proceed with generic review standards
- If one judge fails → use the other judge's findings as single-pass review
- If sub-agents unavailable → fall back to single comprehensive review (not blind)
