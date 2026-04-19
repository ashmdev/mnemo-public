# Interfaces

## Purpose

Design clean, composable Go interfaces that follow the language's implicit satisfaction model, enabling loose coupling and testability.

## When to Use

- Defining contracts between packages or layers
- Enabling dependency injection and testability
- Composing behaviors from small building blocks
- Working with the standard library's interface ecosystem (io, fmt, sort, http)

## Instructions

### Core Principles

1. **Keep interfaces small.** One to three methods is the sweet spot. The bigger the interface, the weaker the abstraction.
2. **Accept interfaces, return structs.** Functions should take interface parameters for flexibility but return concrete types for clarity.
3. **Define interfaces at the consumer, not the producer.** The package that *uses* the behavior defines the interface it needs. The implementing package does not need to know about it.
4. **Interfaces are satisfied implicitly.** Never write `var _ MyInterface = (*MyStruct)(nil)` unless you need a compile-time check in a library package.

### Design Patterns

**Single-method interfaces** are the most powerful. They compose freely and are trivially implemented:

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Closer interface { Close() error }
```

**Compose interfaces from smaller ones:**

```go
type ReadWriter interface {
    Reader
    Writer
}

type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}
```

**Consumer-side definition:**

```go
// In your service package -- define only what you need
type UserStore interface {
    GetUser(ctx context.Context, id string) (User, error)
}

// The concrete implementation lives elsewhere and satisfies this
// without importing your package.
```

### Standard Library Patterns to Follow

- **`io.Reader` / `io.Writer`**: The gold standard. Accept these instead of `*os.File` or `*bytes.Buffer`.
- **`fmt.Stringer`**: Implement `String() string` for human-readable output.
- **`error`**: The most ubiquitous single-method interface.
- **`http.Handler`**: `ServeHTTP(w, r)` -- build middleware by wrapping this.
- **`sort.Interface`**: `Len`, `Less`, `Swap` -- though `slices.SortFunc` is preferred now.

### Interface Segregation

Break fat interfaces into focused ones:

```go
// Bad: forces implementers to provide everything
type Repository interface {
    Create(ctx context.Context, u User) error
    Get(ctx context.Context, id string) (User, error)
    Update(ctx context.Context, u User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter Filter) ([]User, error)
    Count(ctx context.Context) (int, error)
}

// Good: consumers take only what they need
type UserReader interface {
    Get(ctx context.Context, id string) (User, error)
}
type UserWriter interface {
    Create(ctx context.Context, u User) error
    Update(ctx context.Context, u User) error
}
```

### Testing with Interfaces

Interfaces make testing straightforward without mocking frameworks:

```go
type fakeStore struct {
    users map[string]User
}

func (f *fakeStore) Get(_ context.Context, id string) (User, error) {
    u, ok := f.users[id]
    if !ok {
        return User{}, ErrNotFound
    }
    return u, nil
}
```

## Examples

**Bad** -- oversized interface defined at the producer:
```go
// In the database package
type DB interface {
    Query(...) // 15 methods
}
```

**Good** -- minimal interface at the consumer:
```go
// In the handler package
type OrderFinder interface {
    FindOrder(ctx context.Context, id string) (Order, error)
}

func NewHandler(of OrderFinder) *Handler { ... }
```

## Validation

- No interface has more than 5 methods (prefer 1-3)
- Interfaces are defined in the package that consumes them, not the one implementing them
- Functions accept interface types and return concrete types
- No empty interfaces (`interface{}` / `any`) unless truly generic (use generics instead)
- Standard library interfaces (`io.Reader`, `io.Writer`, `error`) are used where applicable
- Test doubles implement interfaces without any mocking framework dependency
