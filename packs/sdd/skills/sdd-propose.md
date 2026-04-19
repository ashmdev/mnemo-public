# SDD: Proposal Phase

## Purpose

Generate and evaluate multiple implementation approaches before committing to one.
This phase prevents the first-idea trap by forcing comparison, surfacing trade-offs
that would otherwise emerge as surprises during implementation.

**Recommended Model:** opus or gemini-2.5-pro (deep reasoning, cheap alternative)

## When to Use

After Explore, for any change involving design decisions. Skip only for mechanical
changes (rename, move, format) where there is genuinely one obvious path.

## Artifacts

| Action  | Path                                              | Description                    |
|---------|---------------------------------------------------|--------------------------------|
| Reads   | `openspec/changes/{name}/exploration.md`          | Codebase findings              |
| Reads   | `openspec/changes/{name}/.openspec.yaml`          | Current phase state            |
| Creates | `openspec/changes/{name}/proposal.md`             | Intent, scope, and approach    |
| Updates | `openspec/changes/{name}/.openspec.yaml`          | Phase transition               |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm you are in the right phase.
Read `exploration.md` to load codebase findings.

### 2. Define the Solution Space

Based on exploration findings, identify the dimensions of choice:
- Where to put the code (new file, existing module, new package)
- How to structure it (new abstraction, extend interface, inline logic)
- What patterns to use (strategy, middleware, event-driven, direct call)
- How to handle errors and how to test it

### 3. Generate Approaches (minimum 2)

For each approach, describe: name, summary (2-3 sentences), step-by-step mechanism,
files affected, and alignment with existing patterns.

Generate at least 2 genuinely different approaches. If you can only think of one,
you have not explored the solution space enough.

### 4. Evaluate Trade-offs

Assess each approach against: complexity, maintainability, performance, risk,
consistency with existing patterns, testability, and scope of changes.

Be honest. Every approach has downsides.

### 5. Recommend One Approach

State clearly: which approach, the decisive trade-off, what you give up, and
how to mitigate the downsides.

### 6. Get Confirmation

Present the proposal to the user. Do not proceed to Specify until approved.

### 7. Write Proposal Artifact

Write to `openspec/changes/{name}/proposal.md`:

```markdown
# Proposal: {change-name}
Date: {YYYY-MM-DD}

## Intent
Why this change is needed and what problem it solves.

## Scope
Which components, files, and interfaces are affected.

## Approach A: {name}
**Summary:** 2-3 sentences.
**Mechanism:** Step-by-step.
**Changes:** Files affected.
**Pros:** Strengths. **Cons:** Weaknesses.

## Approach B: {name}
**Summary:** 2-3 sentences.
**Mechanism:** Step-by-step.
**Changes:** Files affected.
**Pros:** Strengths. **Cons:** Weaknesses.

## Trade-off Comparison
| Criterion | Approach A | Approach B |
|-----------|-----------|-----------|
| Complexity | ... | ... |
| Risk | ... | ... |

## Recommendation
**Chosen:** Approach {X}
**Decisive factor:** What tipped the balance.
**Trade-off accepted:** What we give up.
**Mitigation:** How we manage the downside.
```

### 8. Update State

Update `.openspec.yaml`: set `current_phase: propose`, append `propose` to `completed_phases`.
Save the decision and reasoning in Mnemo.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Prior decisions for related features |
| Store  | After approval | Chosen approach, reasoning, rejected alternatives |

## Validation Checklist

Before proceeding to Specify:

- [ ] `exploration.md` read and incorporated
- [ ] At least 2 distinct approaches generated
- [ ] Trade-offs evaluated honestly for each approach
- [ ] One approach recommended with clear justification
- [ ] User has approved the recommendation
- [ ] `proposal.md` written to `openspec/changes/{name}/`
- [ ] `.openspec.yaml` updated to reflect completed propose phase
- [ ] Decision and reasoning saved to Mnemo

## Common Pitfalls

- **False alternatives:** Two approaches that are trivially the same are not real options.
- **Bias toward complexity:** Simple solutions are usually better. Default to simpler.
- **Ignoring existing patterns:** Inconsistency with the codebase creates maintenance burden.
- **Skipping user approval:** Proceeding without confirmation leads to wasted work.
