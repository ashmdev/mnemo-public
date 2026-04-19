# Mnemo Memory Agent

## Description

Mnemo is a persistent memory system for AI coding agents. It provides cross-session memory, reusable skills, structured workflows, and optional team sync — so agents retain decisions, bugfixes, patterns, and architectural context between sessions and across projects.

## Capabilities

### Persistent Memory
Save and retrieve structured memories that survive across sessions. Each memory has a type, title, content, optional topic key, and project scope. Memories are searchable via full-text and semantic hybrid search.

### Reusable Skills
Load packaged instruction sets for specific tasks. Skills contain detailed guidance for code review, testing, commit hygiene, specification-driven development, and language-specific best practices.

### Structured Workflows
Run multi-phase development workflows (e.g., Specification-Driven Development) with gate checks between phases. Each phase loads relevant skills, memories, and prior artifacts as context.

### Team Sync
Optionally share memories across team members via cloud sync. Memories with `sync_scope=team` are federated and searchable by teammates.

## MCP Server

- **Command**: `mnemo mcp --tools=agent`
- **Transport**: stdio

## MCP Tools (21 total)

### Session Lifecycle (3 tools)
| Tool | Purpose |
|------|---------|
| `mem_session_start` | Begin a session. Provide project name and session ID. |
| `mem_session_end` | End a session by session ID. |
| `mem_session_summary` | Save a session summary as a memory and end the session. |

### Memory Operations (7 tools)
| Tool | Purpose |
|------|---------|
| `mem_save` | Save a memory (decision, bugfix, pattern, learning, etc.). |
| `mem_get` | Retrieve a specific memory by ID. |
| `mem_search` | Search memories using hybrid full-text and semantic search. |
| `mem_update` | Update an existing memory's fields. |
| `mem_context` | Load formatted context summary for a project (use at session start). |
| `mem_capture_passive` | Passively capture session context for later analysis. |
| `mem_save_prompt` | Save a user prompt for future reference and search. |

### Skills and Workflows (5 tools)
| Tool | Purpose |
|------|---------|
| `skill_load` | Load a reusable skill by name. Returns instructions for a specific task. |
| `workflow_phases` | Get the phases of a named workflow. |
| `workflow_start` | Start a new workflow run. Returns a run ID. |
| `workflow_execute` | Execute the current phase of a workflow run. |
| `workflow_complete` | Mark a phase as complete and advance to the next. |

### Utilities (6 tools)
| Tool | Purpose |
|------|---------|
| `mem_suggest_topic` | Suggest a topic_key for a memory based on type, title, content. |
| `mem_sync_status` | Check cloud sync connection state and pending operations. |
| `persona_get` | Get the active persona/personality configuration. |
| `mem_session_start` | (see Session Lifecycle) |
| `mem_session_end` | (see Session Lifecycle) |
| `mem_session_summary` | (see Session Lifecycle) |

## When to Use Each Tool Category

### At Session Start
1. Call `mem_session_start` with project name and a unique session ID.
2. Call `mem_context` to load all relevant memories for the project.
3. Optionally call `mem_search` for specific topics.

### During Work
- **Made an architectural decision?** `mem_save(type="decision")`
- **Fixed a bug?** `mem_save(type="bugfix")`
- **Discovered a project pattern?** `mem_save(type="pattern")`
- **Learned something reusable?** `mem_save(type="learning")`
- **Need guidance on a task?** `skill_load("skill-name")`
- **Running a multi-phase process?** Use the workflow tools.
- **Need to find something?** `mem_search(query="...")`

### At Session End
- Call `mem_session_summary` with a summary of what was accomplished. This saves the summary as a memory and ends the session in one call.

## Available Skills

Load with `skill_load("name")`:

### Core Pack (12 skills)
`memory-protocol`, `commit-hygiene`, `testing-discipline`, `code-review`, `error-handling`, `dependency-management`, `documentation`, `refactoring`, `security-basics`, `performance`, `api-design`, `debugging`

### Go Pack (5 skills)
`go-idioms`, `go-errors`, `go-testing`, `go-concurrency`, `go-project-structure`

### SDD Pack (9 skills)
`sdd-init`, `sdd-specify`, `sdd-blueprint`, `sdd-validate`, `sdd-implement`, `sdd-verify`, `sdd-review`, `sdd-document`, `sdd-complete`

### Framework Skills
`react`, `typescript`, `nextjs`
