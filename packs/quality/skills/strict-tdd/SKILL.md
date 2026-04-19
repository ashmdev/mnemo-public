---
name: strict-tdd
description: >
  Strict Test-Driven Development module enforcing the Red-Green-Refactor cycle
  with mandatory triangulation, safety nets, and assertion quality rules.
  Loaded when TDD mode is enabled and a test runner is available.
  Trigger: "strict tdd", "tdd mode", "test first", "red green refactor".
license: MIT
metadata:
  author: mnemo
  version: "1.0"
  origin: adapted from gentle-ai sdd-apply/strict-tdd
---

## When to Use

- User explicitly enables strict TDD mode
- During SDD (Specification-Driven Development) apply phase with tests
- When implementing features where correctness is critical
- When the project has a working test runner configured
- NOT for trivial config changes, constants, or pure structural work

## Critical Patterns

### The Three Laws of TDD

1. **Do NOT write production code** until you have a failing test
2. **Do NOT write more test** than is necessary to fail
3. **Do NOT write more code** than is necessary to pass the test

### TDD Implementation Cycle

For EVERY task, follow this cycle strictly:

```
FOR EACH TASK:
+-- 0. SAFETY NET (only if modifying existing files)
|   +-- Run existing tests for files being modified
|   +-- Capture baseline: "{N} tests passing"
|   +-- If any FAIL -> STOP, report as "pre-existing failure"
|   +-- Do NOT fix pre-existing failures -- report to orchestrator
|
+-- 1. UNDERSTAND
|   +-- Read the task description
|   +-- Read relevant spec scenarios (these ARE acceptance criteria)
|   +-- Read design decisions (these CONSTRAIN the approach)
|   +-- Read existing code and test patterns (match the style)
|   +-- Determine test layer (unit, integration, e2e)
|
+-- 2. RED -- Write a failing test FIRST
|   +-- Write test(s) describing expected behavior from the spec
|   +-- Prefer pure functions (no side effects = easy to test)
|   +-- Test MUST reference production code that does NOT exist yet
|   +-- If production code already exists: test NEW behavior not yet implemented
|   +-- GATE: Do NOT proceed to GREEN until test is written
|
+-- 3. GREEN -- Write MINIMUM code to pass
|   +-- Implement ONLY what the failing test needs
|   +-- Fake It is VALID (hardcoded returns are OK at this stage)
|   +-- EXECUTE tests -> must PASS
|       +-- Passed -> proceed to TRIANGULATE or REFACTOR
|       +-- Failed -> fix implementation, NOT the test
|   +-- GATE: Do NOT proceed until GREEN confirmed
|
+-- 4. TRIANGULATE (MANDATORY for most tasks)
|   +-- Add a second test case with DIFFERENT inputs/expected outputs
|   +-- EXECUTE tests -> if Fake It breaks (hardcoded won't work):
|       +-- Generalize to real logic
|   +-- Repeat until ALL spec scenarios covered
|   +-- MINIMUM: 2 test cases per behavior (happy path + edge case)
|   +-- WATCH for false GREEN:
|       +-- Test passes because component isn't rendered -> NOT real GREEN
|       +-- Test passes because loop iterates 0 times -> NOT real GREEN
|       +-- Test passes because setup doesn't trigger code path -> NOT real GREEN
|   +-- Skip triangulation ONLY when ALL true:
|       +-- Task is purely structural (config, constant, type export)
|       +-- Literally ONE possible output (no branching, no logic)
|       +-- Note "Triangulation skipped: {reason}" in evidence
|   +-- GATE: All spec scenarios must have tests before REFACTOR
|
+-- 5. REFACTOR -- Improve without changing behavior
|   +-- Extract constants, functions, reduce complexity
|   +-- Improve naming, remove duplication
|   +-- EXECUTE tests after EACH refactoring step
|       +-- Still passing -> safe, continue
|       +-- Failed -> REVERT that step, try smaller
|   +-- GATE: Tests green after EVERY change
|
+-- 6. Mark task complete
+-- 7. Note deviations or issues discovered
```

### Choosing Test Layer

```
Pure logic, utility, calculation, data transform
+-- Unit test (always available)

Component rendering, user interaction, state
+-- Integration test (if tools available)
+-- Unit test with mocks (fallback)

API endpoints, system boundaries, external deps
+-- Integration test (with real DB/services if available)
+-- Unit test with stubs (fallback)

Multi-component flows, user journeys
+-- E2E test (if runner available)
+-- Integration test (fallback)
```

### Assertion Quality Rules

1. **Test behavior, not implementation**: Assert what the code DOES, not HOW
2. **One logical assertion per test**: Multiple asserts OK if testing one behavior
3. **Descriptive test names**: `TestUserService_Create_ReturnsErrorWhenEmailDuplicate`
4. **No testing private methods**: Test through the public API
5. **No flaky tests**: No sleep(), no timing dependencies, deterministic data
6. **Test the sad path**: Error cases are just as important as success cases
7. **Arrange-Act-Assert**: Clear separation in every test function

### Evidence Table

After completing each task, produce an evidence table:

```markdown
| Task | Red (test) | Green (impl) | Triangulation | Refactor | Tests |
|------|-----------|-------------|---------------|----------|-------|
| 1.1  | auth_test.go:15 | auth.go:10 | 2 cases | extracted helper | 5/5 |
| 1.2  | db_test.go:30 | db.go:20 | 3 cases | skipped (clean) | 8/8 |
```

---

## Decision Tree

```
Task assigned
|
+-- Existing files being modified?
|   +-- YES -> Run safety net (existing tests)
|   |   +-- Tests fail? -> STOP, report pre-existing failure
|   |   +-- Tests pass -> Record baseline, continue
|   +-- NO -> Skip safety net
|
+-- Write failing test (RED)
|   +-- Test compiles? -> Good
|   +-- Test runs and FAILS? -> Correct, proceed
|   +-- Test PASSES? -> Wrong test, fix it
|
+-- Write minimum code (GREEN)
|   +-- Test passes? -> Proceed
|   +-- Test fails? -> Fix code, NOT test
|
+-- Triangulate
|   +-- Purely structural? -> Skip with note
|   +-- Logic involved? -> Add 2+ test cases
|   +-- All pass? -> Proceed to refactor
|
+-- Refactor
    +-- Tests still green after each change? -> Continue
    +-- Test broke? -> Revert, try smaller change
```

---

## Instructions

1. Before ANY implementation, verify a test runner works for the project
2. Follow the cycle strictly -- no shortcuts, no skipping RED phase
3. Each completed task must have its evidence table entry
4. When blocked, report to the orchestrator rather than skipping tests
5. Track test count at each stage to prove no regressions
6. Use `mem_search(query: "testing patterns", project: "{project}")` to find project-specific test conventions

---

## Rules

- **MUST** write failing test BEFORE production code -- no exceptions
- **MUST** triangulate with 2+ test cases unless task is purely structural
- **MUST** run tests after every refactoring step
- **MUST NOT** fix pre-existing test failures -- report them
- **MUST NOT** skip safety net when modifying existing files
- **MUST NOT** use `sleep()`, timing-dependent assertions, or non-deterministic data
- **MUST NOT** test implementation details (private methods, internal state)
- **MUST NOT** mark task complete if any test is failing
- Tests that pass trivially (empty renders, zero iterations) are NOT valid GREEN

---

## Examples

```
Task: Implement ValidateEmail function

RED:
  func TestValidateEmail_ValidEmail(t *testing.T) {
    err := ValidateEmail("user@example.com")
    assert.NoError(t, err)
  }
  // Fails: ValidateEmail doesn't exist yet

GREEN:
  func ValidateEmail(email string) error {
    return nil // Fake it
  }
  // Passes

TRIANGULATE:
  func TestValidateEmail_InvalidEmail(t *testing.T) {
    err := ValidateEmail("not-an-email")
    assert.Error(t, err)
  }
  // Fails: Fake it returns nil for everything

  // Generalize:
  func ValidateEmail(email string) error {
    if !strings.Contains(email, "@") {
      return fmt.Errorf("invalid email: missing @")
    }
    return nil
  }

REFACTOR:
  // Extract regex pattern, add more edge cases
  // Run tests after each change
```
