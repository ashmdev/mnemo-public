# SDD: Verification Phase

## Purpose

Validate the implementation against the delta specification point by point. Verification
is not "does it look right" but a systematic check of every requirement, scenario, and
edge case. This phase catches gaps that self-review during implementation inevitably misses.

**Recommended Model:** codex-5.4 or opus (critical evaluation, bug finding)

## When to Use

After all implementation tasks are complete. Do not skip this phase even for small
changes. The cost of verification is low; the cost of shipping spec violations is high.

## Artifacts

| Action  | Path                                                      | Description               |
|---------|-----------------------------------------------------------|---------------------------|
| Reads   | `openspec/changes/{name}/specs/{domain}/spec.md`          | Delta specifications      |
| Reads   | `openspec/changes/{name}/tasks.md`                        | Task completion state     |
| Reads   | `openspec/changes/{name}/design.md`                       | Technical approach        |
| Reads   | `openspec/changes/{name}/.openspec.yaml`                  | Current phase state       |
| Creates | `openspec/changes/{name}/verify-report.md`                | Verification results      |
| Updates | `openspec/changes/{name}/.openspec.yaml`                  | Phase transition          |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase.
Load the delta specs, tasks, and design for reference.

### 2. Verify Each Requirement

For every requirement in the delta spec (ADDED, MODIFIED, REMOVED):

For ADDED/MODIFIED requirements:
- Execute each Given/When/Then scenario
- Check the outcome matches exactly
- Record PASS/FAIL with evidence

For REMOVED requirements:
- Confirm the behavior no longer exists
- Verify no code references remain

### 3. Test Edge Cases

For every edge case in the delta spec:
- Reproduce the scenario
- Verify behavior matches the spec
- Write a test if one does not exist

### 4. Run Existing Tests

Execute the project's test suite. All pre-existing tests MUST still pass.
Failures require investigation: legitimate regression or test needing update.

### 5. Write Missing Tests

For requirements not covered by existing tests, write new tests that directly
verify each scenario. Cover both success and failure paths.

### 6. Run Static Analysis

Run linting and type checking. Fix all errors. Review warnings related to new code.

### 7. Write Verify Report

Write to `openspec/changes/{name}/verify-report.md`:

```markdown
# Verification Report: {change-name}
Date: {YYYY-MM-DD}
Spec: specs/{domain}/spec.md

## Requirement Results
| REQ-ID | Description | Status | Evidence |
|--------|-------------|--------|----------|
| REQ-1  | {desc}      | PASS   | Test xyz passes |
| REQ-2  | {desc}      | FAIL   | Expected X, got Y |

## Scenario Results
| REQ-ID | Scenario | Status | Notes |
|--------|----------|--------|-------|
| REQ-1  | Happy path | PASS | Verified via integration test |
| REQ-1  | Empty input | PASS | Returns 400 as specified |

## Edge Case Results
| # | Scenario | Status | Notes |
|---|----------|--------|-------|
| 1 | {case}   | PASS   | {detail} |

## Test Results
- Pre-existing tests: {X} passed, {Y} failed
- New tests written: {count}
- Coverage delta: {before}% -> {after}%

## Static Analysis
- Errors: {count} (all fixed)
- Warnings: {count new} ({count} fixed, {count} accepted)

## Summary
- **Overall status:** PASS / FAIL / PASS WITH NOTES
- **Blocking issues:** {list or "none"}
- **Non-blocking observations:** {list}
```

### 8. Update State

Update `.openspec.yaml`: set `current_phase: verify`, append `verify` to `completed_phases`.
Save findings in Mnemo.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Spec and design for comparison |
| Store  | End   | Bugs found, quality patterns, verification outcome |

## Validation Checklist

Before proceeding to Document:

- [ ] `verify-report.md` written to `openspec/changes/{name}/`
- [ ] Every delta spec requirement checked with evidence
- [ ] Every scenario executed and recorded
- [ ] Edge cases tested
- [ ] Existing test suite passes (no regressions)
- [ ] New tests written for uncovered requirements
- [ ] Linter and type checker pass
- [ ] All blocking issues fixed or deferred with user approval
- [ ] `.openspec.yaml` updated to reflect completed verify phase

## Common Pitfalls

- **Confirmation bias:** Looking for evidence it works instead of trying to break it.
- **Skipping edge cases:** Normal input covers maybe 60% of real usage.
- **Ignoring regressions:** A failing pre-existing test is not someone else's problem.
- **Accepting all deviations:** Some indicate spec violations that need fixing.
