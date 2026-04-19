# Core: Testing Discipline

## Purpose

Write tests that catch real bugs, document intended behavior, and give confidence to
refactor. Testing is not a checkbox — it is a design tool that shapes how code is
structured and how regressions are prevented.

## When to Use

Before, during, and after implementation. The question is never "should I write tests?"
but "what kind of tests does this change need?"

## Instructions

### 1. Test Hierarchy

Choose the right level for what you are verifying:

| Level | Tests | Speed | Scope | When |
|-------|-------|-------|-------|------|
| **Unit** | Individual functions, methods | Fast (ms) | Single component | Always |
| **Integration** | Component interactions, DB queries | Medium (s) | Multiple components | When components interact |
| **E2E** | Full user flows | Slow (s-min) | Entire system | Critical paths only |

**Rule of thumb:** If a unit test can catch it, do not write an integration test for it.
Push testing as low in the hierarchy as possible.

### 2. Table-Driven Tests

For functions with multiple input/output combinations, use table-driven tests:

```go
tests := []struct {
    name     string
    input    string
    expected int
    wantErr  bool
}{
    {name: "empty string", input: "", expected: 0, wantErr: false},
    {name: "single digit", input: "5", expected: 5, wantErr: false},
    {name: "negative", input: "-3", expected: -3, wantErr: false},
    {name: "invalid", input: "abc", expected: 0, wantErr: true},
    {name: "overflow", input: "99999999999999", expected: 0, wantErr: true},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Parse(tt.input)
        if tt.wantErr { require.Error(t, err); return }
        require.NoError(t, err)
        require.Equal(t, tt.expected, got)
    })
}
```

The same pattern works in any language. The key: each case is a row, not a separate function.

### 3. What to Test

- **Happy path:** The normal, expected usage
- **Edge cases:** Empty input, zero values, max values, boundary conditions
- **Error paths:** Invalid input, missing dependencies, timeout, permission denied
- **State transitions:** Before/after for anything that mutates state
- **Concurrency:** If the code is concurrent, test concurrent access

### 4. What NOT to Test

- **Private implementation details:** Test behavior through public interfaces. If you refactor internals, tests should not break.
- **Framework/library code:** Do not test that `json.Marshal` works. Test that your code uses it correctly.
- **Trivial getters/setters:** A function that returns a field value does not need a test.
- **Third-party API behavior:** Mock the boundary, test your code's handling of responses.

### 5. Test Naming

Names should describe the scenario, not the implementation:

```
Good: TestParseAmount_NegativeValue_ReturnsError
Good: TestCreateUser_DuplicateEmail_ReturnsConflict
Good: test_checkout_with_expired_coupon_raises_validation_error

Bad:  TestParse
Bad:  TestCreateUser2
Bad:  test_function_works
```

Pattern: `Test<Function>_<Scenario>_<ExpectedOutcome>`

### 6. Test Structure

Every test has three parts. Keep them visually distinct:

```go
func TestTransfer_InsufficientBalance_ReturnsError(t *testing.T) {
    // Arrange
    account := NewAccount(balance: 100)

    // Act
    err := account.Transfer(200, targetAccount)

    // Assert
    require.ErrorIs(t, err, ErrInsufficientBalance)
    require.Equal(t, 100, account.Balance()) // unchanged
}
```

### 7. Coverage Targets

- **Aim for 80% line coverage** as a project baseline. Not because 80% is magic, but because chasing 100% leads to testing trivial code while missing important behavior.
- **Focus coverage on business logic.** HTTP handlers, database adapters, and config parsing benefit more from integration tests.
- **Never game coverage.** A test that calls a function without asserting anything is worse than no test — it creates false confidence.

### 8. Test Independence

- Tests must not depend on execution order.
- Tests must not share mutable state.
- Each test sets up its own preconditions and cleans up after itself.
- If tests need a database, use transactions that roll back or isolated test databases.

## Output Format

When writing tests, present them with a brief summary:

```markdown
### Tests Added
| Test | Scenario | Assertion |
|------|----------|-----------|
| TestCreateUser_ValidInput_Succeeds | Normal creation | User returned, no error |
| TestCreateUser_DuplicateEmail_Fails | Email already exists | ErrConflict returned |
| TestCreateUser_EmptyName_Fails | Missing required field | Validation error |
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before writing tests | Testing conventions, mock boundaries, fixture patterns |
| Store | After establishing pattern | New test patterns, mock strategies, coverage decisions |

## Validation Checklist

- [ ] Tests cover happy path, edge cases, and error paths
- [ ] Table-driven format used for multi-case scenarios
- [ ] Test names describe scenario and expected outcome
- [ ] No tests depend on execution order or shared mutable state
- [ ] Mocks are at component boundaries, not on internal functions
- [ ] No tests without assertions
- [ ] All new tests pass; all existing tests still pass
