# Mnemo Memory Protocol

You have access to Mnemo, a persistent memory system via MCP tools. Mnemo gives you cross-session memory, reusable skills, and structured development workflows. You MUST use it actively throughout every session to build and leverage institutional knowledge.

## Tools Available

You have these Mnemo MCP tools:

- `mem_session_start` — Begin a new work session
- `mem_session_end` — End the current session
- `mem_session_summary` — Save session summary and end session (preferred over mem_session_end)
- `mem_context` — Load context from previous sessions (skills inventory, recent memories, session history)
- `mem_save` — Save a memory (decision, bugfix, learning, discovery, pattern, architecture, config, preference)
- `mem_search` — Search past memories by keywords, with optional team-wide federated search
- `mem_get` — Retrieve a specific memory by ID
- `mem_update` — Update an existing memory
- `mem_capture_passive` — Extract learnings from complex reasoning or discussions
- `mem_suggest_topic` — Get a suggested topic_key for a memory
- `mem_sync_status` — Check cloud sync connection status
- `skill_load` — Load a reusable skill pack by name
- `workflow_phases` — Get phases of a development workflow
- `workflow_start` — Start a new workflow run
- `workflow_execute` — Execute the current phase of a workflow
- `workflow_complete` — Complete a phase and advance to the next

---

## Session Lifecycle

### On Session Start (MANDATORY)

Execute these steps at the beginning of EVERY session:

1. Start the session:
   ```
   mem_session_start(project="<project-name>", session_id="<unique-id>")
   ```
   Derive `project` from the working directory name. Generate a unique session ID using a timestamp or UUID.

2. Load context:
   ```
   mem_context(project="<project-name>")
   ```
   Read the returned context carefully. It contains prior decisions, known bugs, architectural patterns, preferences, skills inventory, and session history relevant to this project.

3. Search for relevant memories when working on a specific area:
   ```
   mem_search(query="<topic>", project="<project-name>")
   ```

### On Session End (MANDATORY)

Before ending any session, save a summary:

```
mem_session_summary(session_id="<session-id>", summary="<what was accomplished>")
```

This saves the summary as a memory and ends the session. Include: what was built, decisions made, issues encountered, and next steps.

---

## Memory Protocol — When and How to Save

### Memory Types

| Type | When to Save | Example |
|------|-------------|---------|
| `decision` | Architecture or implementation choices with rationale | Chose PostgreSQL over MongoDB for relational integrity |
| `bugfix` | Bug fixes with root cause and solution | Fixed race condition in auth middleware caused by shared state |
| `learning` | Patterns, gotchas, best practices discovered | React useEffect cleanup required for WebSocket subscriptions |
| `discovery` | New findings about the codebase or tools | Found undocumented API endpoint for batch operations |
| `pattern` | Reusable code patterns or approaches | Repository pattern with generics for all database entities |
| `architecture` | System design, data flow, component relationships | Event-driven architecture for order processing pipeline |
| `config` | Environment setup, tool configuration, build settings | Webpack config requires specific loader order for CSS modules |
| `preference` | User preferences for code style, tooling, workflows | User prefers functional components with hooks over class components |

### Save Format

```
mem_save(
  title="Short searchable summary",
  content="Detailed explanation with context, rationale, and specifics",
  type="decision",
  topic_key="decision/auth",
  project="my-project"
)
```

### Topic Key Convention

Use hierarchical format: `<type>/<domain>[-<detail>]`

Examples:
- `decision/auth` — Authentication decisions
- `decision/database-schema` — Database schema choices
- `bugfix/api-timeout` — API timeout bug fixes
- `learning/react-patterns` — React pattern learnings
- `architecture/event-system` — Event system architecture
- `pattern/error-handling` — Error handling patterns
- `config/docker` — Docker configuration
- `discovery/legacy-api` — Legacy API discoveries
- `preference/code-style` — Code style preferences

Topic keys enable upsert behavior: saving with the same `topic_key` updates the existing memory rather than creating duplicates.

### When to Save — Decision Guide

**Always save after:**
- Making a technical choice between alternatives (decision)
- Fixing a bug that took significant investigation (bugfix)
- Discovering something non-obvious about the codebase (discovery)
- Establishing a pattern that should be reused (pattern)
- Defining or changing system architecture (architecture)
- Learning something that would help in future sessions (learning)
- Noting a user preference for how things should be done (preference)
- Setting up or changing configuration (config)

**Do NOT save:**
- Trivial changes (fixing typos, simple renames)
- Information already in the codebase comments
- Temporary debugging notes

---

## Passive Capture

After complex reasoning, multi-step debugging, or lengthy discussions that produced insights:

```
mem_capture_passive(
  content="<paste the relevant reasoning or discussion>",
  project="<project-name>"
)
```

This extracts and stores learnings automatically. Use it when the conversation itself contains valuable knowledge that might otherwise be lost.

---

## Search and Recall

### Local Project Search

```
mem_search(query="authentication token refresh", project="my-project")
```

Search before:
- Starting work on a feature — find prior decisions and patterns
- Encountering a familiar-seeming problem — find past bugfixes
- Making a decision — find prior decisions on the topic
- Implementing a pattern — find established patterns

### Federated Team Search

Search across team members' shared memories:

```
mem_search(query="deployment pipeline", sync_scope="team")
```

Use `sync_scope="team"` when looking for knowledge that teammates may have captured: cross-project patterns, shared infrastructure decisions, team conventions.

---

## Sync Status

Check cloud sync connection:

```
mem_sync_status()
```

Returns connection state, pending operations, and last sync time. Verify sync status before ending sessions that contain important decisions, to ensure they propagate to the team.

---

## Skills

Load reusable skill packs for domain-specific instructions:

```
skill_load(name="<skill-name>", project="<project-name>")
```

### Available Skill Packs

| Pack | Skills | Description |
|------|--------|-------------|
| **core** | 12 skills | General development: code-review, testing, refactoring, debugging, documentation, git, security, performance, accessibility, api-design, database, deployment |
| **go** | 5 skills | Go development: go-idioms, go-concurrency, go-testing, go-errors, go-modules |
| **sdd** | 9 skills | Specification-Driven Development: spec-writing, contract-first, test-from-spec, validation, schema-design, api-contract, doc-generation, change-management, review-checklist |
| **react** | 1 skill | React development patterns and best practices |
| **typescript** | 1 skill | TypeScript patterns, type safety, and idioms |
| **nextjs** | 1 skill | Next.js development patterns |

Load skills at the start of relevant work. They provide structured instructions that improve code quality and consistency.

---

## Workflows

Mnemo supports structured multi-phase development workflows.

### Specification-Driven Development (SDD)

The primary workflow. Get its phases:

```
workflow_phases(name="sdd")
```

### Starting a Workflow

```
workflow_start(
  workflow_name="sdd",
  change_name="auth-feature",
  project="my-project",
  work_dir="/path/to/project"
)
```

Returns a `run_id` for tracking the workflow instance.

### Executing Phases

```
workflow_execute(run_id="<run-id>")
```

Returns the current phase's skill content, relevant memories, and prior artifacts as context. Follow the instructions in the returned content.

### Completing Phases

```
workflow_complete(
  run_id="<run-id>",
  phase="<phase-name>",
  summary="<what was accomplished>"
)
```

Validates gate conditions and advances to the next phase.

---

## Memory Management

### Retrieve a Specific Memory

```
mem_get(id="<memory-id>")
```

### Update an Existing Memory

```
mem_update(id="<memory-id>", content="<updated content>")
```

Update memories to correct or enrich them as understanding evolves.

### Suggest a Topic Key

```
mem_suggest_topic(title="<title>", type="<type>", content="<content>")
```

Returns a heuristic suggestion for topic_key when you are unsure what convention to use.

---

## Quick Reference

### Session Template

```
# Start
mem_session_start(project="myapp", session_id="2026-03-25-feature-auth")
mem_context(project="myapp")

# Work... save memories as you go
mem_save(title="Chose JWT over session cookies", content="...", type="decision", topic_key="decision/auth", project="myapp")

# End
mem_session_summary(session_id="2026-03-25-feature-auth", summary="Implemented JWT auth with refresh tokens. Chose RS256 for token signing. Next: add rate limiting.")
```

### Memory Save Checklist

Before ending a session, ask yourself:
- Did I make any decisions? Save as `decision`.
- Did I fix any non-trivial bugs? Save as `bugfix`.
- Did I learn something new about the codebase or tools? Save as `learning` or `discovery`.
- Did I establish a pattern that should be reused? Save as `pattern`.
- Did I change or define architecture? Save as `architecture`.
- Did I note a user preference? Save as `preference`.
- Did I change configuration? Save as `config`.
