# Project Layout

## Purpose

Structure Go projects for clarity, maintainability, and proper encapsulation using standard conventions, build tags, and code generation.

## When to Use

- Starting a new Go project or service
- Restructuring an existing project that has grown disorganized
- Deciding where new packages, binaries, or assets belong
- Setting up build constraints, embedding, or code generation

## Instructions

### Recommended Directory Structure

```
myproject/
  cmd/
    myapp/
      main.go           # Entry point, wiring only
    mytool/
      main.go           # Second binary
  internal/
    auth/               # Private to this module
      auth.go
      auth_test.go
    storage/
      postgres.go
      postgres_test.go
  domain/               # Core types and interfaces (exported)
    user.go
    order.go
  handler/              # HTTP/gRPC handlers (exported)
    user.go
  go.mod
  go.sum
  Makefile
```

### Key Directories

**`cmd/`** -- One subdirectory per binary. Each `main.go` should be thin: parse flags, wire dependencies, call `run()`. No business logic here.

```go
func main() {
    cfg := config.Load()
    db := storage.New(cfg.DatabaseURL)
    srv := handler.NewServer(db)
    log.Fatal(srv.ListenAndServe(cfg.Addr))
}
```

**`internal/`** -- Packages under `internal/` are only importable by code rooted at the parent of `internal/`. This is enforced by the Go toolchain. Use it for implementation details that should not become public API.

**Domain packages** -- Export core types and interfaces. Keep them dependency-free. Name them after the domain concept, not the technical layer (`user`, `order`, not `models`, `types`).

### Avoid `pkg/`

The `pkg/` directory has no special meaning in Go. It adds a useless path segment. Place exported packages at the module root or use meaningful names directly.

### go.mod Best Practices

- Module path should match the repository: `module github.com/org/project`.
- Pin Go version: `go 1.23` (minimum version your code requires).
- Run `go mod tidy` before every commit to remove unused dependencies.
- Use `go mod vendor` only if you need hermetic builds or offline support.

### Build Tags

Use `//go:build` (not the legacy `// +build`) for conditional compilation:

```go
//go:build integration

package storage_test

func TestPostgresIntegration(t *testing.T) { ... }
```

Run with: `go test -tags=integration ./...`

Common tag patterns:
- `integration` -- slow tests requiring external services
- `linux`, `darwin`, `windows` -- OS-specific code
- `!production` -- debug utilities excluded from release builds

### go:embed

Embed static files directly into the binary:

```go
import "embed"

//go:embed templates/*.html
var templates embed.FS

//go:embed version.txt
var version string
```

Rules:
- The `//go:embed` directive must be immediately above the variable.
- Variable must be of type `string`, `[]byte`, or `embed.FS`.
- Paths are relative to the source file.
- Use `embed.FS` for directories, `string` or `[]byte` for single files.

### go:generate

Automate code generation with directives in source files:

```go
//go:generate stringer -type=Status
//go:generate mockgen -source=store.go -destination=mock_store.go
```

Run all generators: `go generate ./...`

Best practices:
- Commit generated files to version control.
- Run `go generate` in CI to verify generated files are up to date.
- Place the directive in the file closest to what it generates.

### Package Naming

- Short, lowercase, single-word names: `auth`, `storage`, `handler`.
- No underscores or camelCase: `httputil`, not `http_util` or `httpUtil`.
- No stutter: `storage.New()`, not `storage.NewStorage()`.
- Package name should describe what it provides, not what it contains.

### Makefile Conventions

```makefile
.PHONY: build test lint

build:
	go build -o bin/ ./cmd/...

test:
	go test -race -count=1 ./...

lint:
	golangci-lint run

generate:
	go generate ./...

tidy:
	go mod tidy
	go mod verify
```

## Examples

**Bad** -- flat structure, everything exported:
```
myproject/
  main.go
  user.go
  db.go
  handler.go
  utils.go
```

**Good** -- layered, encapsulated, multiple binaries supported:
```
myproject/
  cmd/api/main.go
  internal/storage/postgres.go
  domain/user.go
  handler/user.go
```

## Validation

- `cmd/` contains only `main.go` files with minimal wiring logic
- `internal/` is used for packages that must not be imported externally
- No `pkg/` directory exists unless there is a documented reason
- `go.mod` is tidy (`go mod tidy` produces no diff)
- Build tags use `//go:build` syntax, not legacy `// +build`
- `//go:embed` variables are the correct type for their content
- Package names are short, lowercase, and do not stutter with exported names
- Generated files are committed and CI verifies they are current
