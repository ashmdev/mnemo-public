# Error Handling

## Purpose

Handle errors idiomatically in Go using wrapping, sentinel errors, custom types, and the errors package for reliable, debuggable error chains.

## When to Use

- Returning and checking errors from function calls
- Creating domain-specific error types for programmatic handling
- Wrapping errors to preserve context across call stacks
- Distinguishing between operational errors and programming bugs

## Instructions

### Fundamental Rules

1. **Always handle errors.** Never discard with `_`. If you truly cannot handle it, document why with a comment.
2. **Return errors, do not panic.** Reserve `panic` for truly unrecoverable programmer bugs (unreachable code, violated invariants in init). Never use `panic` for control flow.
3. **Wrap errors with context** using `fmt.Errorf("doing X: %w", err)`. The `%w` verb creates a chain that `errors.Is` and `errors.As` can traverse.
4. **Do not double-wrap.** If a called function already provides sufficient context, do not add redundant prefixes.

### Error Wrapping with %w

```go
func LoadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("load config %s: %w", path, err)
    }
    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parse config %s: %w", path, err)
    }
    return &cfg, nil
}
```

### Sentinel Errors

Define package-level errors for conditions callers need to check programmatically:

```go
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
)
```

Check with `errors.Is`, which traverses the entire wrap chain:

```go
if errors.Is(err, ErrNotFound) {
    // handle missing resource
}
```

### Custom Error Types

Use when errors carry structured data callers need:

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s %s", e.Field, e.Message)
}
```

Extract with `errors.As`:

```go
var ve *ValidationError
if errors.As(err, &ve) {
    log.Printf("invalid field %s: %s", ve.Field, ve.Message)
}
```

### Error Handling in HTTP Handlers

Map domain errors to HTTP status codes at the boundary:

```go
func handleGet(w http.ResponseWriter, r *http.Request) {
    item, err := store.Get(r.Context(), id)
    if err != nil {
        switch {
        case errors.Is(err, ErrNotFound):
            http.Error(w, "not found", http.StatusNotFound)
        case errors.Is(err, ErrUnauthorized):
            http.Error(w, "unauthorized", http.StatusUnauthorized)
        default:
            log.Printf("unexpected error: %v", err)
            http.Error(w, "internal error", http.StatusInternalServerError)
        }
        return
    }
    json.NewEncoder(w).Encode(item)
}
```

### Multi-Error Collection

Use `errors.Join` (Go 1.20+) to aggregate multiple errors:

```go
func validateUser(u User) error {
    var errs []error
    if u.Name == "" {
        errs = append(errs, &ValidationError{Field: "name", Message: "required"})
    }
    if u.Email == "" {
        errs = append(errs, &ValidationError{Field: "email", Message: "required"})
    }
    return errors.Join(errs...)
}
```

### Deferred Cleanup Errors

Handle errors from deferred `Close` calls without shadowing the main error:

```go
func writeFile(path string, data []byte) (retErr error) {
    f, err := os.Create(path)
    if err != nil {
        return fmt.Errorf("create %s: %w", path, err)
    }
    defer func() {
        if closeErr := f.Close(); closeErr != nil && retErr == nil {
            retErr = fmt.Errorf("close %s: %w", path, closeErr)
        }
    }()
    _, err = f.Write(data)
    return err
}
```

## Examples

**Bad** -- discarded error, naked string error:
```go
data, _ := os.ReadFile(path)
return errors.New("something went wrong")
```

**Good** -- wrapped with context, programmatically checkable:
```go
data, err := os.ReadFile(path)
if err != nil {
    return fmt.Errorf("read user config %s: %w", path, err)
}
```

## Validation

- No `_` on error returns without a justifying comment
- All `fmt.Errorf` wrapping uses `%w` (not `%v` or `%s`) for the error verb
- Sentinel errors are `var Err... = errors.New(...)`, not created inline
- `errors.Is` and `errors.As` are used instead of type assertions or string matching
- No `panic` calls in library code or business logic
- HTTP/gRPC boundaries translate domain errors to status codes, never leak raw errors
