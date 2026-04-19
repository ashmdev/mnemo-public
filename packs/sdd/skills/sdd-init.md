# SDD: Initialization Phase

## Purpose

Bootstrap the OpenSpec directory structure and establish project context before any
implementation work begins. This phase creates the scaffold that all subsequent phases
write into, and loads prior knowledge to prevent repeated mistakes.

**Recommended Model:** sonnet (lightweight, fast context gathering)

## When to Use

Every SDD session starts here. No exceptions. Even familiar projects need a fresh
baseline scan to catch stale assumptions and recent changes.

## Artifacts

| Action  | Path                                | Description                     |
|---------|-------------------------------------|---------------------------------|
| Creates | `openspec/`                         | Root directory                  |
| Creates | `openspec/specs/`                   | Main spec directory             |
| Creates | `openspec/changes/`                 | Active changes directory        |
| Creates | `openspec/config.yaml`              | Project-level OpenSpec config   |
| Creates | `openspec/changes/{name}/`          | Directory for the current change|
| Creates | `openspec/changes/{name}/.openspec.yaml` | State tracking file        |

> See `_shared/openspec-convention.md` for full directory and format reference.

## Instructions

### 1. Check for Existing OpenSpec Structure

Look for an `openspec/` directory in the project root. If it exists:
- Read `openspec/config.yaml` for project settings
- List `openspec/changes/` for any in-progress changes
- Read `.openspec.yaml` in each active change to understand current state
- Read `openspec/specs/` for existing domain specifications

If no `openspec/` directory exists, create the full scaffold.

### 2. Create OpenSpec Scaffold (if new)

```
mkdir -p openspec/specs openspec/changes
```

Write `openspec/config.yaml`:
```yaml
project: {project-name}
default_domain: core
spec_format: gherkin
keywords: rfc2119
created_at: {ISO timestamp}
```

### 3. Load Project Memory

Query Mnemo for existing project context:
```
mnemo recall --project <project> --scope context
mnemo recall --project <project> --scope decisions --recent 10
mnemo recall --project <project> --scope learnings --recent 5
```

### 4. Scan Project Structure

Identify the project's technical foundation:
- **Languages and versions:** Check config files (package.json, go.mod, pyproject.toml)
- **Framework and libraries:** Note major dependencies and their versions
- **Directory layout:** Map the top-level organization
- **Build system:** How the project builds, tests, and deploys

### 5. Identify Patterns and Conventions

Read representative files to understand naming conventions, error handling patterns,
testing approach, import organization, and documentation style.

### 6. Create Change Directory

For the current request, create the change folder and state file:

```
mkdir -p openspec/changes/{change-name}
```

Write `openspec/changes/{change-name}/.openspec.yaml`:
```yaml
change: {change-name}
current_phase: init
completed_phases: []
started_at: {ISO timestamp}
updated_at: {ISO timestamp}
```

### 7. Assess Scope

Evaluate the request against the project context:
- **Scope:** How many files/components will this touch?
- **Complexity:** Straightforward change or requires design?
- **Risk:** Could this break existing functionality?
- **Recommended SDD path:** Full workflow or abbreviated?

### 8. Save Initial Context

Store the assessment in Mnemo and update `.openspec.yaml`:
```
mnemo store --project <project> --scope context --key sdd-session \
  --content "<structured assessment>"
```

Update `.openspec.yaml` to `current_phase: init`, `completed_phases: [init]`.

## Mnemo Integration

| Action | When | What |
|--------|------|------|
| Recall | Start of phase | Project context, recent decisions, learnings |
| Store  | End of phase   | Session context with scope assessment        |

## Validation Checklist

Before proceeding to Explore:

- [ ] OpenSpec directory structure exists (`openspec/specs/`, `openspec/changes/`)
- [ ] `openspec/config.yaml` present and populated
- [ ] Change directory created at `openspec/changes/{change-name}/`
- [ ] `.openspec.yaml` state file written with `current_phase: init`
- [ ] Project structure and tech stack identified
- [ ] Coding patterns and conventions documented
- [ ] Mnemo memory consulted for relevant history
- [ ] Scope assessment complete with complexity estimate

## Common Pitfalls

- **Skipping memory recall:** You lose context from previous sessions and repeat mistakes.
- **Not checking for existing openspec/:** Recreating the scaffold overwrites prior specs.
- **Shallow scanning:** Reading only top-level files misses patterns in core modules.
- **Over-scoping:** If the request is simple, say so. Not everything needs full 9-phase treatment.
