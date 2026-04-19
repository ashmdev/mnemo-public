# Core: Error Handling

## Purpose

Handle errors explicitly, consistently, and informatively so that failures are
debuggable, recoverable where possible, and never silently swallowed. Error handling
is not an afterthought — it is a core part of the program's logic.

## When to Use

Every time you write code that can fail. If a function can return an error, you must
handle it. If an operation can panic or throw, you must decide what happens when it does.

## Instructions

### 1. The Cardinal Rule: Never Swallow Errors

```go
// FORBIDDEN — the error disappears
result, _ := doSomething()

// FORBIDDEN — caught and ignored
try { doSomething() } catch (e) { }

// REQUIRED — handle or propagate
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doing something for user %s: %w", userID, err)
}
```

Every suppressed error is a future debugging nightmare. If you genuinely do not care
about an error, document why with a comment.

### 2. Wrap Errors with Context

When propagating errors, add context that helps trace the failure path:

```go
// Go
user, err := repo.FindUser(id)
if err != nil {
    return fmt.Errorf("finding user %s: %w", id, err)
}
```

```python
# Python
try:
    user = repo.find_user(id)
except UserNotFound as e:
    raise ServiceError(f"finding user {id}") from e
```

```typescript
// TypeScript
try {
    const user = await repo.findUser(id);
} catch (err) {
    throw new ServiceError(`finding user ${id}`, { cause: err });
}
```

Good context answers: **what were you trying to do** and **with what inputs?**

### 3. Sentinel Errors vs Typed Errors

**Sentinel errors** are predefined values for expected, well-known failure conditions:

```go
var ErrNotFound = errors.New("not found")
var ErrConflict = errors.New("conflict")
var ErrUnauthorized = errors.New("unauthorized")
```

Use them when the caller needs to check the *kind* of error without parsing messages.

**Typed errors** carry additional data:

```go
type ValidationError struct {
    Field   string
    Message string
}
func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s %s", e.Field, e.Message)
}
```

Use typed errors when the caller needs structured information about the failure.

**Guideline:** Start with sentinel errors. Upgrade to typed errors when you need to
attach data. Do not create a type for every error — that is overengineering.

### 4. Error Logging vs Error Returning

**Log at the boundary, return everywhere else.**

```
handler (LOG here)  ←  service (RETURN)  ←  repository (RETURN)
```

- **Return** errors up the call stack with added context at each level
- **Log** errors at the system boundary (HTTP handler, CLI command, background job entry point)
- **Never** log and return the same error — that produces duplicate log entries

```go
// In the service layer: RETURN, do not log
func (s *Service) CreateUser(input CreateUserInput) (*User, error) {
    if err := s.repo.Save(user); err != nil {
        return nil, fmt.Errorf("saving user: %w", err) // return, no log
    }
    return user, nil
}

// In the handler: LOG at the boundary
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.CreateUser(input)
    if err != nil {
        h.logger.Error("create user failed", "error", err, "input", input)
        respondError(w, err) // map to HTTP status
        return
    }
}
```

### 5. Error Mapping at Boundaries

Domain errors must be translated at system boundaries:

| Domain Error | HTTP Status | gRPC Code |
|-------------|-------------|-----------|
| `ErrNotFound` | 404 | NOT_FOUND |
| `ErrConflict` | 409 | ALREADY_EXISTS |
| `ErrUnauthorized` | 401 | UNAUTHENTICATED |
| `*ValidationError` | 400 | INVALID_ARGUMENT |
| Unexpected error | 500 | INTERNAL |

Never leak internal error messages to external consumers. Map to safe, generic messages.

### 6. Panic/Exception Policy

- **Panics (Go):** Only for programmer errors (nil pointer where nil is impossible). Never for expected conditions.
- **Exceptions (Python/JS/Java):** Use for exceptional conditions. Do not use for control flow.
- **Recover/catch at the boundary:** HTTP middleware, background job runners, and CLI entry points should catch panics to prevent process crashes.

### 7. Testing Error Paths

Every error return must have a corresponding test:

```go
func TestCreateUser_DuplicateEmail_ReturnsConflict(t *testing.T) {
    repo.On("Save").Return(ErrConflict)
    _, err := service.CreateUser(input)
    require.ErrorIs(t, err, ErrConflict)
}
```

If you cannot trigger the error in a test, reconsider whether the error path is reachable.

## Output Format

When documenting error handling strategy for a component:

```markdown
### Error Handling: <Component>
| Operation | Possible Errors | Handling |
|-----------|----------------|----------|
| FindUser | ErrNotFound | Return to caller with context |
| SaveUser | ErrConflict | Return to caller with context |
| SaveUser | unexpected DB error | Return wrapped, log at boundary |
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before implementation | Error conventions, sentinel error definitions |
| Store | After establishing patterns | Error types, mapping rules, logging conventions |

## Validation Checklist

- [ ] No errors silently swallowed (every `_` or empty catch justified)
- [ ] Errors wrapped with context at every propagation point
- [ ] Logging happens at boundaries only, not at every layer
- [ ] Sentinel errors defined for expected failure conditions
- [ ] Domain errors mapped to appropriate protocol errors at boundaries
- [ ] Internal error details not leaked to external consumers
- [ ] Error paths tested
