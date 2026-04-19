# Table-Driven Tests

## Purpose

Write structured, maintainable Go tests using table-driven patterns, subtests, helpers, parallelism, and benchmarks.

## When to Use

- Testing functions with multiple input/output combinations
- Building a test suite that is easy to extend with new cases
- Running subtests in parallel for speed
- Benchmarking hot paths and comparing implementations

## Instructions

### Table-Driven Test Structure

The core pattern: define cases as a slice of structs, iterate with `t.Run`:

```go
func TestParseAmount(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int64
        wantErr bool
    }{
        {name: "valid cents", input: "12.34", want: 1234},
        {name: "whole number", input: "5", want: 500},
        {name: "negative", input: "-1.50", want: -150},
        {name: "empty string", input: "", wantErr: true},
        {name: "letters", input: "abc", wantErr: true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseAmount(tt.input)
            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got != tt.want {
                t.Errorf("ParseAmount(%q) = %d, want %d", tt.input, got, tt.want)
            }
        })
    }
}
```

### Naming Conventions

- Test case `name` field should describe the scenario, not the expected result.
- Use lowercase with spaces: `"empty input"`, `"negative value"`, `"duplicate key"`.
- Names appear in `-run` filters: `go test -run TestParseAmount/empty_input`.

### Parallel Tests

Call `t.Parallel()` in the subtest to run cases concurrently. Capture the loop variable:

```go
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        got := Transform(tt.input)
        if got != tt.want {
            t.Errorf("got %v, want %v", got, tt.want)
        }
    })
}
```

Note: as of Go 1.22, the loop variable is per-iteration, so the capture issue is resolved. For earlier versions, shadow with `tt := tt`.

### Test Helpers with t.Helper

Mark helper functions with `t.Helper()` so failure messages point to the caller:

```go
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}
```

### Testing Error Conditions

Check specific errors using `errors.Is` in tests:

```go
{name: "not found", id: "missing", wantErr: ErrNotFound},

// In the loop:
if tt.wantErr != nil {
    if !errors.Is(err, tt.wantErr) {
        t.Fatalf("got error %v, want %v", err, tt.wantErr)
    }
    return
}
```

### Testdata and Golden Files

Store fixtures in `testdata/` (ignored by `go build`):

```go
func TestRender(t *testing.T) {
    input := readFile(t, "testdata/input.json")
    want := readFile(t, "testdata/golden.html")
    got := Render(input)
    if got != want {
        t.Errorf("output mismatch;\ngot:\n%s\nwant:\n%s", got, want)
    }
}

func readFile(t *testing.T, path string) string {
    t.Helper()
    data, err := os.ReadFile(path)
    if err != nil {
        t.Fatalf("read %s: %v", path, err)
    }
    return string(data)
}
```

### Benchmark Patterns

```go
func BenchmarkHash(b *testing.B) {
    data := []byte("benchmark input")
    b.ResetTimer()
    for b.Loop() {
        Hash(data)
    }
}
```

Run benchmarks: `go test -bench=. -benchmem ./...`

### Race Detection

Always run CI tests with the race detector: `go test -race ./...`

The `-race` flag instruments memory accesses and will cause a test failure if a data race is detected at runtime.

## Examples

**Bad** -- separate test functions per case, no structure:
```go
func TestParseFoo(t *testing.T) { ... }
func TestParseBar(t *testing.T) { ... }
func TestParseBaz(t *testing.T) { ... }
```

**Good** -- single table, subtests, easy to extend:
```go
func TestParse(t *testing.T) {
    tests := []struct{ name, in string; want int }{
        {"foo", "foo", 1},
        {"bar", "bar", 2},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) { ... })
    }
}
```

## Validation

- All multi-case tests use table-driven pattern with `t.Run` subtests
- Test names describe the scenario, not the expectation
- `t.Helper()` is called at the top of every test helper function
- `t.Parallel()` is used where tests have no shared mutable state
- `-race` flag is included in CI test commands
- Benchmarks use `b.Loop()` (Go 1.24+) or `b.N` loop and call `b.ResetTimer()` after setup
