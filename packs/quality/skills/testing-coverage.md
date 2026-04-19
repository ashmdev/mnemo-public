# Quality: Testing Coverage Enforcement

## Purpose

Ensure every change has appropriate test coverage. Not 100% coverage for its own sake,
but strategic coverage of business logic, edge cases, and regression-prone areas.
Mnemo tracks testing gaps over time so the team knows where risk accumulates.

## When to Use

- After implementing a feature or fix (verify tests exist)
- User says "check coverage", "test coverage", "revisar tests", "cobertura"
- During code review (verify PR includes tests)
- When planning testing improvements

## Instructions

### 1. Coverage Assessment

For any change, verify:

| What Changed | Required Tests |
|-------------|---------------|
| New function/method | Unit test with happy path + edge cases |
| Bug fix | Regression test proving the fix works |
| API endpoint | Integration test with request/response validation |
| Business logic | Unit tests covering all branches |
| Configuration change | Smoke test verifying config loads |
| UI component | Render test + interaction test |

### 2. What MUST Be Tested

**Always test:**
- Public API contracts (inputs → outputs)
- Error handling paths (what happens when things fail?)
- Boundary conditions (0, 1, MAX, empty, nil, negative)
- Business rules (the logic that makes money)
- Security-sensitive code (auth, validation, sanitization)

**Skip testing:**
- Simple getters/setters with no logic
- Framework boilerplate (the framework tests that)
- Constants and type definitions
- Third-party library internals

### 3. Test Quality Checks

A test that exists but doesn't catch bugs is worse than no test (false confidence).

**Good test indicators:**
- Tests behavior, not implementation (survives refactoring)
- Has meaningful assertions (not just "no error")
- Tests edge cases, not just happy path
- Is readable (another dev understands what's being tested)
- Runs fast (< 1 second for unit tests)

**Bad test indicators:**
- ❌ `assert(result != nil)` — what SHOULD result be?
- ❌ Mocks everything — testing the mocks, not the code
- ❌ Tests implementation details — breaks on every refactor
- ❌ No error path testing — only happy path
- ❌ Flaky — passes sometimes, fails sometimes

### 4. Coverage Gaps Detection

When reviewing code, check for untested paths:

```bash
# Go
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

# JavaScript/TypeScript
npx jest --coverage

# Python
pytest --cov={module} --cov-report=term-missing
```

Focus on **uncovered branches**, not just line coverage.

### 5. Save Testing Gaps to Memory

When discovering areas with insufficient coverage:
```
mem_save(
  title: "Testing gap: {area}",
  type: "discovery",
  project: "{project}",
  topic_key: "testing-gaps/{module}",
  content: "## Gap\n{what's untested}\n## Risk\n{what could break}\n## Recommended\n{what tests to add}"
)
```

When establishing testing patterns:
```
mem_save(
  title: "Testing pattern: {pattern}",
  type: "pattern",
  project: "{project}",
  topic_key: "testing/{pattern-name}",
  content: "## Pattern\n{description}\n## Example\n{code snippet}\n## When\n{when to use}"
)
```

### 6. Minimum Coverage Standards

| Category | Minimum | Target |
|----------|---------|--------|
| Business logic | 80% | 90%+ |
| API endpoints | 70% | 85%+ |
| Utilities | 60% | 80%+ |
| UI components | 50% | 70%+ |
| Configuration | Smoke test | Full validation |

These are guidelines, not gospel. Use judgment for each project.

## Graceful Degradation

- If Mnemo unavailable → perform coverage checks without memory
- If coverage tool unavailable → manual review of test presence
