# Quality: Documentation-Code Alignment

## Purpose

Ensure documentation accurately reflects the current state of the code. Stale docs
are worse than no docs — they actively mislead. Mnemo tracks documentation gaps
so the team can prioritize doc updates alongside code changes.

## When to Use

- After changing public APIs, configuration, or behavior
- User says "check docs", "update docs", "docs alignment", "revisar docs", "actualizar docs"
- During code review (verify docs were updated with code)
- When onboarding new team members reveals gaps

## Instructions

### 1. What MUST Stay Aligned

| Code Change | Documentation to Update |
|-------------|------------------------|
| Public API change | API docs, README examples, changelog |
| New feature | User guide, feature list, changelog |
| Config change | Configuration reference, .env.example |
| Breaking change | Migration guide, changelog, README |
| Dependency change | Installation guide, requirements |
| CLI command change | Help text, man page, README |
| Error code change | Error reference, troubleshooting guide |

### 2. Alignment Check Process

For any set of code changes:

**Step 1: Identify documentation touchpoints**
```bash
# Find all docs that might reference changed files/functions
grep -rl "{function_name}\|{module_name}" docs/ README.md *.md
```

**Step 2: Verify each touchpoint**
- Does the doc describe the CURRENT behavior (not the old one)?
- Are code examples still valid and runnable?
- Are configuration options complete and correct?
- Are error messages and codes up to date?

**Step 3: Check for orphaned docs**
- Docs that reference deleted functions or features
- Examples using deprecated APIs
- Screenshots of old UI

### 3. README Health Check

Every project README must have and keep current:

| Section | Check |
|---------|-------|
| Description | Matches current project purpose |
| Installation | Steps actually work on a fresh machine |
| Quick start | Example runs without modification |
| Configuration | All options documented with defaults |
| API reference | All public endpoints/functions listed |
| Contributing | Setup steps are current |

### 4. Changelog Discipline

Every user-facing change gets a changelog entry:

```markdown
## [Unreleased]

### Added
- {new feature description} (#issue-number)

### Changed
- {behavior change description} (#issue-number)

### Fixed
- {bug fix description} (#issue-number)

### Removed
- {removed feature} (#issue-number)

### Breaking
- {breaking change with migration path} (#issue-number)
```

### 5. Code Comments Alignment

Internal documentation matters too:
- Function doc comments match actual parameters and return values
- Package-level docs describe current purpose
- Inline comments explain WHY, not WHAT (and are still true)
- TODO comments have issue references or are removed

### 6. Save Documentation Gaps to Memory

When discovering stale or missing docs:
```
mem_save(
  title: "Doc gap: {area}",
  type: "discovery",
  project: "{project}",
  topic_key: "docs-gaps/{area}",
  content: "## Gap\n{what's missing/stale}\n## Impact\n{who gets confused}\n## Fix\n{what to update}"
)
```

When establishing documentation conventions:
```
mem_save(
  title: "Doc convention: {convention}",
  type: "pattern",
  project: "{project}",
  topic_key: "conventions/docs",
  content: "## Convention\n{description}\n## Where\n{which docs}\n## Example\n{good example}"
)
```

### 7. Automated Checks

Where possible, automate alignment verification:

```bash
# Check for broken internal links
find docs/ -name "*.md" -exec grep -l "\[.*\](.*\.md)" {} \; | while read f; do
  grep -oP '\[.*?\]\(\K[^)]+' "$f" | while read link; do
    [ ! -f "$(dirname "$f")/$link" ] && echo "BROKEN: $f -> $link"
  done
done

# Check if .env.example matches actual env vars used
grep -roh 'os\.Getenv("[^"]*")' . | sort -u > /tmp/used_envs
cat .env.example | grep -v '^#' | cut -d= -f1 > /tmp/documented_envs
diff /tmp/used_envs /tmp/documented_envs
```

## Graceful Degradation

- If Mnemo unavailable → perform doc checks without memory
- If no docs directory → check README only
- If no changelog → suggest creating one
