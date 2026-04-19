# Mnemo Memory Protocol for Windsurf

You have access to Mnemo, a persistent memory system via MCP tools. Mnemo gives you cross-session memory, reusable skills, and structured development workflows. Use it actively throughout every session.

---

## 1. Session Lifecycle

### Session Start

Every session MUST begin with these steps in order:

1. **Start the session**:
   ```
   mem_session_start(project="<project-name>", session_id="<unique-id>")
   ```
   Use the working directory name as `project`. Generate a unique session ID (e.g., timestamp or UUID).

2. **Load context**:
   ```
   mem_context(project="<project-name>")
   ```
   This returns the skills inventory, recent memories, and session history. Read it carefully before proceeding — it contains prior decisions, known bugs, architectural patterns, and preferences that apply to your current work.

3. **Search for relevant memories** if working on a specific feature or area:
   ```
   mem_search(query="<topic>", project="<project-name>")
   ```

### Session End

Before ending any session:

1. **Save a session summary**:
   ```
   mem_session_summary(session_id="<session-id>", summary="<what was accomplished>")
   ```
   This both saves the summary as a memory and ends the session. Include: what was built, key decisions made, issues encountered, and next steps.

If you need to end the session without a summary (rare):
```
mem_session_end(session_id="<session-id>")
```

---

## 2. Memory Protocol — When to Save

Call `mem_save` whenever you produce knowledge worth remembering. Every memory needs a `title`, `content`, `type`, and ideally a `topic_key` and `project`.

### Memory Types

| Type | When to Save | Example |
|------|-------------|---------|
| `decision` | Architecture or implementation choices with rationale | Chose PostgreSQL over MongoDB for relational integrity |
| `bugfix` | Bug fixes with root cause and solution | Fixed race condition in auth middleware caused by shared state |
| `learning` | Patterns, gotchas, best practices discovered | React useEffect cleanup required for WebSocket subscriptions |
| `discovery` | New findings about the codebase or tools | Found undocumented API endpoint that handles batch operations |
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

Use a hierarchical format: `<type>/<domain>[-<detail>]`

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

## 3. Passive Capture

After complex reasoning, multi-step debugging, or lengthy discussions that produced insights:

```
mem_capture_passive(
  content="<paste the relevant reasoning or discussion>",
  project="<project-name>"
)
```

This extracts and stores learnings automatically. Use it when the conversation itself contains valuable knowledge that might be lost.

---

## 4. Search and Recall

### Local Search

```
mem_search(query="authentication token refresh", project="my-project")
```

Search before:
- Starting work on a feature (find prior decisions and patterns)
- Encountering a familiar-seeming problem (find past bugfixes)
- Making a decision (find prior decisions on the topic)
- Implementing a pattern (find established patterns)

### Federated Team Search

To search across team members' shared memories:

```
mem_search(query="deployment pipeline", sync_scope="team")
```

Use `sync_scope="team"` when looking for knowledge that teammates may have captured — cross-project patterns, shared infrastructure decisions, team conventions.

---

## 5. Sync Status

Check the cloud sync connection:

```
mem_sync_status()
```

Returns connection state, pending operations, and last sync time. Use this to verify memories are being synced to the team, especially before ending a session with important decisions.

---

## 6. Skills

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

Load skills at the start of relevant work. Skills provide structured instructions that improve code quality and consistency.

---

## 7. Workflows

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

Returns a `run_id` for tracking.

### Executing Phases

```
workflow_execute(run_id="<run-id>")
```

Returns the current phase's skill content, relevant memories, and prior artifacts. Follow the instructions in the returned content.

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

## 8. Memory Management

### Retrieve a Specific Memory

```
mem_get(id="<memory-id>")
```

### Update an Existing Memory

```
mem_update(id="<memory-id>", content="<updated content>")
```

Use this to correct or enrich existing memories as understanding evolves.

### Suggest a Topic Key

```
mem_suggest_topic(title="<title>", type="<type>", content="<content>")
```

Returns a heuristic suggestion for topic_key if you are unsure what to use.

---

## 9. Quick Reference

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
