# Core: Project Structure

## Purpose

Establish clear conventions for where files, packages, and configurations live so that
anyone on the team can find anything without asking. A well-organized project reduces
onboarding time, prevents duplicate code, and makes automated tooling easier to configure.

## When to Use

When starting a project, adding new files, or restructuring existing code. Before creating
any new file, ask: "Where does this belong?" If the answer is not immediately obvious, the
structure needs clarification.

## Instructions

### 1. Standard Directory Layout

Most projects converge on a similar top-level structure regardless of language:

```
project-root/
  cmd/              # Application entry points (main packages)
  internal/         # Private application code (not importable by others)
  pkg/              # Public library code (if applicable)
  api/              # API definitions: OpenAPI specs, protobuf, GraphQL schemas
  config/           # Configuration files, templates, defaults
  migrations/       # Database migrations (numbered, sequential)
  scripts/          # Build, deploy, operational scripts
  docs/             # Architecture docs, ADRs, guides
  tests/            # Integration and e2e tests (unit tests go beside source)
  .github/          # CI/CD workflows, issue templates
  Makefile           # (or Taskfile, justfile) — common development commands
  README.md
  .gitignore
```

Adapt to your language ecosystem. Go uses `cmd/` and `internal/`. Node.js uses `src/`
and `dist/`. Python uses a package directory matching the project name. Follow the
conventions your ecosystem expects.

### 2. Source Code Organization

#### By domain, not by type

```
# GOOD — organized by business domain
internal/
  billing/
    invoice.go
    invoice_test.go
    payment.go
    payment_test.go
  user/
    user.go
    user_test.go
    repository.go

# BAD — organized by file type
internal/
  models/
    invoice.go
    user.go
  services/
    billing_service.go
    user_service.go
  repositories/
    billing_repo.go
    user_repo.go
```

Domain-based organization keeps related code together. When you work on billing, everything
you need is in one place. Type-based organization scatters billing logic across three directories.

### 3. Test Placement

**Unit tests:** Next to the source file they test.

```
internal/billing/invoice.go
internal/billing/invoice_test.go
```

**Integration tests:** In a `tests/` or `integration/` directory at the project root.

```
tests/
  integration/
    billing_test.go     # Tests billing with real database
    api_test.go         # Tests HTTP endpoints end-to-end
```

**Test fixtures and helpers:**

```
tests/
  testdata/            # Test input files, golden files
  helpers/             # Shared test utilities
```

### 4. Configuration Files

- **Application config:** `config/` directory with environment-specific files
- **Tool config:** Project root (`.eslintrc`, `golangci.yml`, `tsconfig.json`)
- **CI/CD:** `.github/workflows/`, `.gitlab-ci.yml`, or equivalent
- **Docker:** `Dockerfile` at root, `docker-compose.yml` at root

```
config/
  config.go           # Configuration struct and loading logic
  config.yaml         # Default configuration values
  config.test.yaml    # Test environment overrides
```

### 5. Naming Conventions by Language

| Language | Files | Packages/Modules | Variables | Constants |
|----------|-------|-----------------|-----------|-----------|
| Go | `snake_case.go` | `lowercase` | `camelCase` | `CamelCase` (exported) |
| TypeScript | `kebab-case.ts` | `kebab-case` dirs | `camelCase` | `UPPER_SNAKE` |
| Python | `snake_case.py` | `snake_case` | `snake_case` | `UPPER_SNAKE` |
| Rust | `snake_case.rs` | `snake_case` | `snake_case` | `UPPER_SNAKE` |

Follow what exists. If the project mixes conventions, standardize incrementally in
dedicated refactor commits, not mixed in with feature work.

### 6. When to Split a File

Split a file when:
- It exceeds ~300-500 lines (language-dependent)
- It contains multiple unrelated types or concepts
- You find yourself scrolling past large sections to find what you need
- Two developers frequently need to edit different parts simultaneously

Split by domain concept, not by function count.

### 7. When to Split a Package

Split a package when:
- It has grown beyond ~15 files
- It has multiple unrelated responsibilities
- Different parts change for different reasons (Single Responsibility Principle)
- You want to enforce an API boundary between subsystems

Keep a package when:
- All files are tightly related and change together
- Splitting would create packages with only one file
- The "new package" would just be a utils/helpers dumping ground

### 8. Monorepo vs Multi-Repo

| Factor | Monorepo | Multi-Repo |
|--------|----------|-----------|
| Shared code | Easy (direct imports) | Harder (versioned libraries) |
| CI/CD | Complex (selective builds) | Simple (per-repo pipelines) |
| Refactoring | Atomic across services | Coordinated across repos |
| Team autonomy | Lower (shared tooling) | Higher (independent stacks) |
| Dependency management | Unified | Independent |

Default to monorepo for small teams (<10 devs) and tightly coupled services.
Consider multi-repo when teams are autonomous and services are truly independent.

## Output Format

When proposing structure changes:

```markdown
### Structure Change
- **Action:** Created `internal/notification/` package
- **Contains:** email.go, sms.go, push.go, notifier.go (interface)
- **Reason:** Notification logic was mixed into handlers across 4 packages
- **Impact:** Handlers now depend on `notification.Notifier` interface
```

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Before creating files | Project structure conventions, package map |
| Store | After structural decision | New package layout, naming conventions |

## Validation Checklist

- [ ] New files placed in the correct domain package
- [ ] Source organized by domain, not by type
- [ ] Unit tests co-located with source files
- [ ] Integration tests in dedicated test directory
- [ ] Configuration files in consistent locations
- [ ] Naming conventions match language and project standards
- [ ] No catch-all `utils/`, `helpers/`, or `common/` packages
- [ ] File/package splits justified by size or responsibility
