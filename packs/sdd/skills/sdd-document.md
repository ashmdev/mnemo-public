# SDD: Documentation Phase

## Purpose

Archive the completed change, merge delta specs into the main specs, update project
documentation, and create a changelog entry. This phase finalizes the OpenSpec lifecycle
by promoting change artifacts into the canonical specification.

**Recommended Model:** sonnet (clear writing, routine task)

## When to Use

After verification passes. Documentation written before verification risks describing
behavior that does not match reality.

## Artifacts

| Action  | Path                                                       | Description                     |
|---------|------------------------------------------------------------|---------------------------------|
| Reads   | `openspec/changes/{name}/specs/{domain}/spec.md`           | Delta specifications            |
| Reads   | `openspec/changes/{name}/verify-report.md`                 | Verification results            |
| Reads   | `openspec/changes/{name}/.openspec.yaml`                   | Current phase state             |
| Reads   | `openspec/specs/{domain}/spec.md`                          | Main specifications             |
| Updates | `openspec/specs/{domain}/spec.md`                          | Merged delta specs              |
| Creates | `openspec/changes/archive/YYYY-MM-DD-{name}/`             | Archived change folder          |
| Updates | `openspec/changes/{name}/.openspec.yaml`                   | Final phase state               |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Resume from State

Read `.openspec.yaml` to confirm current phase. Read the verify report to confirm
the change passed verification.

### 2. Merge Delta Specs into Main Specs

For each delta spec in `openspec/changes/{name}/specs/{domain}/spec.md`:

- **ADDED requirements:** Append to `openspec/specs/{domain}/spec.md`
- **MODIFIED requirements:** Replace the matching REQ-ID in the main spec
- **REMOVED requirements:** Delete the matching REQ-ID from the main spec

If `openspec/specs/{domain}/spec.md` does not exist yet, create it with the
ADDED requirements as its initial content.

After merging, the main spec reflects the current state of the system.

### 3. Update API Documentation

If the change introduces or modifies a public interface:
- Update or create API reference documentation
- Include endpoints/functions, parameters, return types, error codes, examples
- Match the actual implementation (the code is truth, not the spec)

### 4. Update README

If the change affects how users interact with the project:
- Add/update usage instructions
- Update configuration documentation
- Add examples for new functionality

### 5. Update Inline Documentation

Review new code for documentation needs:
- Public functions need docstrings
- Complex algorithms need WHY comments (not WHAT)
- Non-obvious design choices need brief context comments

### 6. Create Changelog Entry

```markdown
## [version] - YYYY-MM-DD

### Added
- {new feature description}

### Changed
- {modification description}

### Fixed
- {bug fix description}
```

### 7. Archive the Change

Move the entire change directory to the archive:

```
mv openspec/changes/{name}/ openspec/changes/archive/YYYY-MM-DD-{name}/
```

The archived folder retains all artifacts (proposal, specs, design, tasks,
verify-report, .openspec.yaml) for historical reference.

### 8. Archive SDD Session in Mnemo

```
mnemo store --project <project> --scope session-archive \
  --key sdd-{name}-{date} \
  --content "<session summary>"
```

Include: feature name, key decisions, spec summary, design summary, learnings,
verification outcome, files changed.

### 9. Consolidate Mnemo Memory

- Promote broadly applicable learnings to permanent project knowledge
- Tag decisions with the feature name for retrieval
- Clean session-specific memories captured in the archive

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start  | Documentation conventions, prior session archives |
| Store  | Mid    | Session archive with full summary                 |
| Update | End    | Promote learnings, clean temporary memories        |

## Validation Checklist

Before marking the SDD session complete:

- [ ] Delta specs merged into `openspec/specs/{domain}/spec.md`
- [ ] Main specs reflect current system behavior after merge
- [ ] Change directory archived to `openspec/changes/archive/YYYY-MM-DD-{name}/`
- [ ] API documentation reflects the actual implementation
- [ ] README updated if public interface changed
- [ ] Inline documentation added for new public functions
- [ ] Changelog entry written in user-facing language
- [ ] SDD session archived in Mnemo
- [ ] Mnemo memories consolidated (promoted, tagged, cleaned)
- [ ] `.openspec.yaml` reflects final state before archiving

## Common Pitfalls

- **Forgetting to merge deltas:** The main spec becomes stale if deltas are only archived.
- **Documenting the spec, not the implementation:** After verify, the code is truth.
- **Skipping the archive:** Future sessions on the same area start from scratch.
- **Leaving temporary memories:** Session-specific notes cluttering Mnemo.
- **Forgetting the changelog:** Makes the project's history opaque.
