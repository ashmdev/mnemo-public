# Core: Architecture Guard

## Purpose

Enforce system boundaries, dependency rules, and structural consistency so the codebase
stays navigable and maintainable as it grows. Architecture guard is not about preventing
change — it is about ensuring changes respect the contracts that keep components decoupled.

## When to Use

Every time you add a new file, create a new package, or introduce a dependency between
components. Architecture enforcement is continuous, not periodic.

## Instructions

### 1. Dependency Direction

Dependencies flow inward. Inner layers never import from outer layers.

```
Outer (infrastructure)  →  Middle (application)  →  Inner (domain)

handlers/   →  services/   →  domain/
adapters/   →  usecases/   →  entities/
api/        →  app/        →  core/
```

**The rule:** An inner layer must not know about the layer that calls it. Domain logic
does not import HTTP handlers. Services do not import database drivers directly.

```
ALLOWED:     handler imports service, service imports domain
FORBIDDEN:   domain imports handler, service imports handler
FORBIDDEN:   domain imports database driver
```

Use interfaces at boundaries. The service layer defines the interface; the infrastructure
layer implements it.

### 2. Package/Module Boundaries

A package has a clear, single purpose. Test whether a package is well-bounded:

- **Can you describe it in one sentence?** If not, it is doing too much.
- **Does it have a focused public API?** If everything is exported, the boundary is meaningless.
- **Could you replace it without changing other packages?** If not, coupling is too tight.

### 3. Where New Files Go

Before creating a file, answer:

| Question | Determines |
|----------|-----------|
| What layer does this belong to? | Top-level directory |
| What domain concept does it serve? | Package/subdirectory |
| Is it a test? | Goes in the test directory alongside or in `tests/` |
| Is it configuration? | Goes in `config/` or project root |
| Is it a script/tool? | Goes in `scripts/` or `tools/` |

```
# Good placement
internal/billing/invoice.go        # domain logic for billing
internal/billing/invoice_test.go   # tests alongside source
cmd/api/main.go                    # application entry point
scripts/migrate.sh                 # operational tooling

# Bad placement
invoice.go                         # root-level domain file
internal/billing/handler.go        # HTTP handler in domain package
utils/helpers.go                   # catch-all utility dumping ground
```

### 4. When to Create a New Package

Create a new package when:

- A new domain concept emerges that does not fit existing packages
- An existing package has grown beyond ~15 files or ~2000 lines
- Two unrelated concerns are sharing a package because of historical accident
- You need to enforce an API boundary between collaborating teams

Do NOT create a new package when:

- You have just one file. A single-file package is usually premature.
- The functionality is a private helper for an existing package. Keep it internal.
- You are creating `utils/`, `helpers/`, or `common/`. These become dumping grounds. Put the code where it is used.

### 5. Forbidden Patterns

| Pattern | Why It Is Wrong | What To Do Instead |
|---------|----------------|-------------------|
| `utils/` package | Becomes a junk drawer | Put functions in the package that uses them |
| Circular imports | Indicates tangled architecture | Extract shared types into a third package |
| God package | One package that everything depends on | Split by domain concept |
| Shotgun surgery | One change requires editing 10+ files | Consolidate related logic |
| Feature envy | Package A constantly reaches into Package B's internals | Move the logic to B or extract a shared interface |

### 6. Checking Architecture Compliance

Before merging, verify:

```bash
# Check for forbidden imports (example for Go)
grep -r "import.*handler" internal/domain/   # should find nothing
grep -r "import.*database" internal/service/  # should find nothing

# Check package sizes
find internal/ -name "*.go" | xargs wc -l | sort -rn | head -20
```

Consider adopting a dependency linter (Go: `depguard`, JS: `eslint-plugin-import`,
Rust: `cargo-deny`) that enforces these rules automatically.

## Output Format

When making architectural decisions about structure, document them:

```markdown
### Architecture Decision
- **Decision:** Created `internal/notification/` package
- **Reason:** Notification logic (email, SMS, push) was scattered across handlers
- **Boundary:** Exposes `Notifier` interface, hides provider details
- **Dependencies:** Depends on `internal/domain/` only, no outward dependencies
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before creating packages | Existing architecture rules, package map |
| Store | After structural decision | New package boundaries, dependency rules |
| Store | After fixing violations | Architecture violations found and how they were resolved |

## Validation Checklist

- [ ] New code placed in the correct layer and package
- [ ] No dependency direction violations (inner layers do not import outer)
- [ ] No circular dependencies introduced
- [ ] No `utils/`, `helpers/`, or `common/` catch-all packages created
- [ ] New packages have a clear, single-sentence purpose
- [ ] Package public API is minimal and intentional
- [ ] Architecture decisions documented and saved to Mnemo
