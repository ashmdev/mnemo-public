# SDD: Specification Phase

## Purpose

Write delta specs precise enough that a different developer or a fresh AI agent with
no prior context could implement the change correctly. Specs use the OpenSpec delta
format with ADDED/MODIFIED/REMOVED sections and RFC 2119 keywords.

**Recommended Model:** opus or gemini-2.5-pro (precision and completeness)

## When to Use

After the proposal is approved. This is the most important phase in SDD. A good spec
makes implementation straightforward; a vague spec guarantees rework.

## Artifacts

| Action  | Path                                                      | Description              |
|---------|-----------------------------------------------------------|--------------------------|
| Reads   | `openspec/changes/{name}/proposal.md`                     | Approved approach        |
| Reads   | `openspec/specs/{domain}/spec.md`                         | Existing requirements    |
| Reads   | `openspec/changes/{name}/.openspec.yaml`                  | Current phase state      |
| Creates | `openspec/changes/{name}/specs/{domain}/spec.md`          | Delta specifications     |
| Updates | `openspec/changes/{name}/.openspec.yaml`                  | Phase transition         |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase.
Read `proposal.md` for the approved approach.
Read `openspec/specs/{domain}/spec.md` for existing requirements.

### 2. Identify Delta Type

For each requirement affected by this change, classify it:
- **ADDED:** Entirely new behavior not covered by existing specs
- **MODIFIED:** Changes to existing requirements (reference the original REQ-ID)
- **REMOVED:** Behavior that will no longer exist (reference the original REQ-ID)

### 3. Write Requirements with RFC 2119 Keywords

Use precise language:
- **MUST / SHALL:** Mandatory behavior. Implementation fails verification without it.
- **SHOULD:** Recommended behavior. Deviation requires documented justification.
- **MAY:** Optional behavior. Implementation can include or omit it.

Avoid ambiguous words: "should handle gracefully", "works correctly", "as expected".

### 4. Write Given/When/Then Scenarios

For each requirement, write at least one scenario:

```markdown
#### Scenario: {descriptive name}
- **Given** {precondition}
- **When** {action}
- **Then** {expected outcome}
```

Cover the happy path first, then error cases, then edge cases.

### 5. Define API Contracts

For any interface (HTTP, function signature, message format, CLI):
- **Input:** Exact shape, types, required vs optional, validation rules
- **Output:** Shape for success and every error variant
- **Side effects:** State changes (DB writes, events emitted, files created)

### 6. Enumerate Edge Cases

Think adversarially. For each input: empty, null, max size, duplicate, concurrent,
dependency unavailable, valid but semantically nonsensical, insufficient permissions.

### 7. Write Delta Spec Artifact

Write to `openspec/changes/{name}/specs/{domain}/spec.md`:

```markdown
# Delta Spec: {change-name}
Date: {YYYY-MM-DD}
Domain: {domain}
Proposal: proposal.md

## ADDED Requirements

### REQ-{ID}: {Title}
The system MUST {behavior description}.

#### Scenario: {name}
- **Given** {precondition}
- **When** {action}
- **Then** {expected outcome}

#### API Contract
- **Input:** {schema}
- **Output (success):** {schema}
- **Output (error):** {schema per error type}

#### Edge Cases
| # | Scenario | Expected Behavior |
|---|----------|-------------------|
| 1 | {case}   | {behavior}        |

## MODIFIED Requirements

### REQ-{ID}: {Title}
Previously: {old behavior summary}.
The system MUST now {new behavior description}.

## REMOVED Requirements

### REQ-{ID}: {Title}
Removed because: {reason}.
```

### 8. Update State

Update `.openspec.yaml`: set `current_phase: specify`, append `specify` to `completed_phases`.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start | Prior specs for similar features (format/depth reference) |
| Store  | End   | Complete delta specification                              |

## Validation Checklist

Before proceeding to Design:

- [ ] Delta spec written to `openspec/changes/{name}/specs/{domain}/spec.md`
- [ ] Every requirement uses RFC 2119 keywords (MUST/SHALL/SHOULD/MAY)
- [ ] Every requirement has at least one Given/When/Then scenario
- [ ] API contracts fully defined with input, output, and error shapes
- [ ] Edge cases enumerated (minimum 5 for non-trivial features)
- [ ] No ambiguous language remaining
- [ ] MODIFIED requirements reference their original REQ-ID
- [ ] `.openspec.yaml` updated to reflect completed specify phase

## Common Pitfalls

- **Vague criteria:** "Works correctly" is not a spec. Be specific about what correct means.
- **Missing error cases:** The happy path is easy. The value of a spec is in the errors and edges.
- **Wrong delta type:** Modifying an existing requirement and marking it ADDED loses traceability.
- **Over-specification:** Specify behavior and contracts, not implementation details.
