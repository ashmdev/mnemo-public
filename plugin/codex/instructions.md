# Mnemo Memory Protocol for Codex

You have access to persistent memory via Mnemo MCP tools. This protocol defines when and how to use each tool to maintain project context across sessions.

---

## 1. Session Lifecycle

### Starting a Session

At the beginning of every session:

```
1. mem_session_start(project="<project-name>", session_id="<unique-id>")
2. mem_context(project="<project-name>")          # Load all relevant memories
3. mem_search(query="<current task topic>")        # Optional: find specific context
```

The `mem_context` call returns a formatted summary of all saved memories for the project. Read it to understand prior decisions, known bugs, architecture, and patterns before starting work.

### Ending a Session

At the end of every session, call one of:

- **`mem_session_summary(session_id, summary)`** — Saves a session summary as a memory and ends the session. This is the preferred single-call approach.
- **`mem_session_end(session_id)`** — Ends the session without saving a summary. Use only if you already saved the summary separately.

The summary should cover: what was accomplished, key decisions made, open items, and anything the next session should know.

---

## 2. Memory Save Protocol

### When to Save

Save a memory whenever you encounter something worth remembering across sessions. Use `mem_save` with the appropriate type.

### Memory Types

| Type | When to Save | Example |
|------|-------------|---------|
| `decision` | Architectural or design choice made | "Chose PostgreSQL over MongoDB for relational data needs" |
| `bugfix` | Bug found and fixed | "Race condition in worker pool — fixed with mutex in dispatch()" |
| `learning` | Reusable insight discovered | "Go's `json.Decoder` streams better than `json.Unmarshal` for large payloads" |
| `pattern` | Recurring code or project pattern | "All API handlers follow middleware -> validate -> execute -> respond" |
| `architecture` | System structure or component design | "Event bus connects services via NATS; each service owns its schema" |
| `discovery` | Something found during exploration | "Legacy endpoint /v1/sync is still called by mobile clients" |
| `config` | Configuration knowledge | "CI uses GITHUB_TOKEN secret for package registry auth" |
| `preference` | User or project preference | "Team prefers table-driven tests over subtests in Go" |

### mem_save Parameters

```
mem_save(
  title="Short searchable summary",       # Required. Keep under 80 chars.
  content="Full detail of the memory",     # Required. Be thorough.
  type="decision",                         # Required. One of the types above.
  project="my-project",                    # Recommended. Scopes the memory.
  topic_key="architecture/auth",           # Recommended. Enables upsert behavior.
  scope="project",                         # "project" (default) or "personal"
  sync_scope="project",                    # "personal", "project" (default), or "team"
  session_id="current-session-id"          # Recommended. Links memory to session.
)
```

### Save Triggers

Save immediately when any of these occur:
- You make or recommend an architectural decision
- You fix a non-trivial bug
- You discover how something works that was previously unclear
- You identify a recurring pattern in the codebase
- You learn something that would help in future sessions
- The user states a preference about how things should be done
- You encounter configuration that took effort to figure out

---

## 3. Topic Keys Convention

Topic keys enable upsert behavior: saving with an existing topic_key updates the previous memory instead of creating a duplicate.

### Format

Use slash-separated hierarchical keys:

```
<domain>/<subject>
<domain>/<subject>/<detail>
```

### Examples

| Topic Key | Use Case |
|-----------|----------|
| `architecture/database` | Database design decisions |
| `architecture/auth` | Authentication system design |
| `architecture/api` | API design conventions |
| `bugfix/race-condition` | Specific bug category |
| `config/ci` | CI/CD configuration |
| `config/docker` | Docker setup |
| `pattern/error-handling` | Error handling conventions |
| `pattern/testing` | Testing conventions |
| `preference/code-style` | Code style preferences |

Use `mem_suggest_topic(title, type, content)` if you are unsure what topic key to use.

---

## 4. Skills

Skills are packaged instruction sets you can load for guidance on specific tasks.

### Loading a Skill

```
skill_load(name="code-review", project="my-project")
```

This returns the full skill content — detailed instructions, checklists, and conventions for that task. Follow the returned instructions.

### Available Skills

**Core Pack (12 skills)**
| Skill | Purpose |
|-------|---------|
| `memory-protocol` | How to use Mnemo effectively |
| `commit-hygiene` | Commit message and branching conventions |
| `testing-discipline` | Testing strategy and coverage |
| `code-review` | Code review checklist and process |
| `error-handling` | Error handling patterns |
| `dependency-management` | Managing dependencies safely |
| `documentation` | Documentation standards |
| `refactoring` | Refactoring techniques and safety |
| `security-basics` | Security review checklist |
| `performance` | Performance analysis approach |
| `api-design` | API design conventions |
| `debugging` | Systematic debugging process |

**Go Pack (5 skills)**
| Skill | Purpose |
|-------|---------|
| `go-idioms` | Idiomatic Go patterns |
| `go-errors` | Go error handling conventions |
| `go-testing` | Go testing patterns and table tests |
| `go-concurrency` | Goroutines, channels, sync patterns |
| `go-project-structure` | Go project layout conventions |

**SDD Pack — Specification-Driven Development (9 skills)**
| Skill | Purpose |
|-------|---------|
| `sdd-init` | Initialize an SDD workflow |
| `sdd-specify` | Write specifications |
| `sdd-blueprint` | Create implementation blueprints |
| `sdd-validate` | Validate specs against requirements |
| `sdd-implement` | Implement from blueprints |
| `sdd-verify` | Verify implementation against specs |
| `sdd-review` | Review completed implementation |
| `sdd-document` | Generate documentation |
| `sdd-complete` | Finalize and close out |

**Framework Skills**
| Skill | Purpose |
|-------|---------|
| `react` | React component patterns and hooks |
| `typescript` | TypeScript idioms and type patterns |
| `nextjs` | Next.js app structure and conventions |

---

## 5. Workflows

Workflows are multi-phase development processes with gate checks between phases.

### Discovering Workflows

```
workflow_phases(name="sdd")    # List phases in the SDD workflow
```

### Running a Workflow

```
# 1. Start a run
run_id = workflow_start(
  workflow_name="sdd",
  change_name="auth-feature",
  project="my-project",
  work_dir="/path/to/project"
)

# 2. Execute the current phase — returns skill content, memories, and prior artifacts
workflow_execute(run_id=run_id)

# 3. Do the work for that phase...

# 4. Mark phase complete and advance
workflow_complete(
  run_id=run_id,
  phase="specify",
  summary="Wrote OpenAPI spec for auth endpoints",
  gate_pass=true
)

# 5. Repeat steps 2-4 for each phase
```

Each call to `workflow_execute` loads the skill for the current phase plus any relevant memories and artifacts from prior phases.

---

## 6. Search

### Basic Search

```
mem_search(query="authentication flow", project="my-project")
```

Returns the most relevant memories matching the query using hybrid full-text and semantic search.

### Filtered Search

```
mem_search(query="error handling", type="pattern", project="my-project", limit=5)
```

### Team Search

```
mem_search(query="deployment process", sync_scope="team")
```

Searches across all team members' shared memories via cloud federation.

---

## 7. Context Loading

At session start, call:

```
mem_context(project="my-project", scope="project")
```

This returns a formatted summary of all memories for the project, organized by type. Use it to quickly understand:
- Prior architectural decisions
- Known bugs and fixes
- Established patterns
- Configuration knowledge
- User preferences

---

## 8. Passive Capture

Use `mem_capture_passive` to record session context without creating a formal memory:

```
mem_capture_passive(
  content="User described auth requirements: OAuth2 with PKCE, refresh tokens, 1hr expiry",
  project="my-project",
  session_id="current-session-id"
)
```

Use this for information that might be useful later but does not warrant a formal memory save yet.

---

## 9. Sync Status

Check the cloud sync state at any time:

```
mem_sync_status()
```

Returns: connection state, pending operations count, and last sync timestamp. Useful for verifying that team-scoped memories are being shared.

---

## 10. Updating and Retrieving Memories

### Get a Specific Memory

```
mem_get(id="memory-uuid")
```

### Update a Memory

```
mem_update(id="memory-uuid", content="Updated content", title="Updated title")
```

Only provided fields are changed. Use this to correct or enrich existing memories.

---

## 11. Prompt Saving

Save notable user prompts for future reference:

```
mem_save_prompt(content="the user prompt text", session_id="current-session-id", project="my-project")
```

---

## 12. Quick Reference

### Session Start Checklist
1. `mem_session_start(project, session_id)`
2. `mem_context(project)`
3. Read the context. Optionally `mem_search` for specific topics.

### During Work
- Decision made -> `mem_save(type="decision")`
- Bug fixed -> `mem_save(type="bugfix")`
- Pattern found -> `mem_save(type="pattern")`
- Insight gained -> `mem_save(type="learning")`
- Architecture defined -> `mem_save(type="architecture")`
- Config discovered -> `mem_save(type="config")`
- Need task guidance -> `skill_load("skill-name")`
- Multi-phase process -> `workflow_start` / `workflow_execute` / `workflow_complete`

### Session End Checklist
1. `mem_session_summary(session_id, summary)` — saves summary and ends session.
