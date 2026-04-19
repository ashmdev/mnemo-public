# Mnemo User Guide

Persistent memory for AI agent teams. This guide covers installation, setup, and daily usage.

## Installation

### Homebrew (macOS/Linux)

```bash
brew install ashmdev/tap/mnemo
```

### Go Install

```bash
go install github.com/ashmdev/mnemo/cmd/mnemo@latest
```

### Binary Download

Download from [GitHub Releases](https://github.com/ashmdev/mnemo/releases).

## Setup

### Connect to Your AI Agent

```bash
# Auto-detect and configure all installed agents
mnemo agent install --detect

# Or install for a specific agent
mnemo agent install claude-code
mnemo agent install cursor
mnemo agent install windsurf
mnemo agent install opencode
mnemo agent install gemini-cli
mnemo agent install codex
mnemo agent install antigravity
mnemo agent install copilot
mnemo agent install qwen-code
mnemo agent install kilo-code
mnemo agent install kiro
mnemo agent install generic    # prints JSON for manual configuration
```

After install, **restart your AI agent** to load the MCP configuration.

### What `mnemo agent install` Does

The install process varies by agent, but follows this general flow:

| Step | Claude Code | Cursor | Other agents |
|------|------------|--------|-------------|
| **1. MCP config** | Plugin marketplace + `~/.claude/mcp/mnemo.json` | `~/.cursor/mcp.json` | Agent-specific config file |
| **2. Hooks** | `settings.json` (SessionStart, UserPromptSubmit, Stop, SubagentStop) | N/A | N/A (only Claude Code supports hooks) |
| **3. Scripts** | `~/.claude/scripts/` (6 bash scripts for lifecycle events) | N/A | N/A |
| **4. Memory protocol** | Injected into `~/.claude/CLAUDE.md` with `<!-- mnemo:memory-protocol -->` markers | Rules file in `.cursor/rules/mnemo.mdc` | Agent-specific system prompt file |
| **5. Skill** | `~/.claude/skills/memory-protocol/SKILL.md` | N/A | N/A |

#### Claude Code Install — 5 Compliance Layers

Claude Code gets the most comprehensive install because it supports hooks and skills:

1. **CLAUDE.md injection** — Memory protocol written directly into `~/.claude/CLAUDE.md`. This is part of the system prompt and has the highest priority. Your existing CLAUDE.md content is preserved; Mnemo appends its section using HTML comment markers.

2. **Memory protocol skill** — `~/.claude/skills/memory-protocol/SKILL.md` loaded as a permanent instruction with detailed save triggers and session protocol.

3. **Hooks** — 4 lifecycle hooks in `~/.claude/settings.json`:
   - `SessionStart`: loads Mnemo tools and recovers context after compaction
   - `UserPromptSubmit`: ToolSearch injection on first message + save-nudge after 15 min
   - `Stop`: saves session summary on exit
   - `SubagentStop`: captures subagent work

4. **MCP activity tracker** — In-process tracking that appends save-nudge reminders to `mem_search` and `mem_context` responses when 15+ minutes pass without a save. Works for all 12 agents via MCP.

5. **MCP server instructions** — The MCP initialize response includes a "PROACTIVE SAVE RULE" that all clients read.

#### Plugin Marketplace (Claude Code)

For Claude Code, Mnemo first tries to install as a native plugin via the Claude Code marketplace:

```bash
claude plugin marketplace add ashmdev/mnemo
claude plugin install mnemo
```

If the Claude CLI is not available, it falls back to manual file installation (same result, same artifacts). The plugin includes hooks, skills, and MCP config in a single managed package.

### Verify Installation

```bash
mnemo status           # Check server health and configuration
mnemo version          # Show version
mnemo agent list       # List supported agents and their status
mnemo agent status     # Show which agents are configured
```

### Install Skills

```bash
# Install the core pack (essential skills)
mnemo pack install core

# Install language-specific packs
mnemo pack install go
mnemo pack install react
mnemo pack install typescript
mnemo pack install nextjs

# Install the SDD workflow
mnemo pack install sdd

# Install the quality enforcement pack
mnemo pack install quality
```

## Daily Usage

Once installed, your AI agent automatically:
- Starts the Mnemo server when a session begins
- Loads context from previous sessions via `mem_context`
- Has access to 34 MCP tools for saving, searching, exporting, and managing memories
- Receives save-nudge reminders every 15 minutes (via hooks and MCP activity tracker)
- Follows the memory protocol injected into its system prompt

### Key Tools Your Agent Uses

| Tool | What it does |
|------|-------------|
| `mem_save` | Save a decision, bugfix, pattern, or learning |
| `mem_search` | Search memories by keyword and meaning |
| `mem_context` | Load context at session start |
| `mem_session_summary` | Save session summary at the end |
| `skill_load` | Load a reusable skill by name |
| `workflow_phases` | Get phases of a workflow (e.g., SDD) |
| `mem_export_obsidian` | Export memories as Obsidian markdown vault |
| `mem_merge_projects` | Fix project name drift (rename memories) |

### CLI Commands

```bash
# Search memories
mnemo search "authentication"
mnemo search --team "deployment patterns"    # Federated search

# Manage memories
mnemo save "Title" "Content" --type decision --project my-app
mnemo timeline <memory-id>
mnemo context my-project
mnemo stats

# Skills and content
mnemo skill list
mnemo skill load sdd-init

# Embeddings (optional, enables semantic search)
mnemo embed providers        # List available providers
mnemo embed backfill         # Generate missing embeddings

# Data management
mnemo export backup.json
mnemo import backup.json
```

## Embedding Providers (Optional)

Embeddings enable semantic search (finding memories by meaning, not just keywords).

```bash
# Ollama (local, free)
export MNEMO_EMBED=ollama
ollama pull bge-m3

# OpenAI (cloud, paid)
export MNEMO_EMBED=openai
export OPENAI_API_KEY=sk-...

# Custom HTTP sidecar
export MNEMO_EMBED=http://localhost:8080
```

Without embeddings, search uses FTS5 keyword matching only — still fully functional.

## Team Sync

### Cloud Sync (recommended)

```bash
# Login to Mnemo Cloud
mnemo login --key YOUR_API_KEY --url https://cloud.mnemo.dev

# Push local memories
mnemo push --project my-app

# Pull team memories
mnemo pull

# Check sync status
mnemo team
```

With `MNEMO_CLOUD_URL` configured, `mnemo serve` auto-syncs every 5 minutes.

### Git Chunk Sync (no server needed)

```bash
mnemo sync export --project my-app    # Export new memories as gzip chunk
mnemo sync import                      # Import unread chunks
mnemo sync status                      # Show sync status
```

Chunks are committed to your git repo in `.mnemo/`. Append-only, no merge conflicts.

## Configuration

Config file: `~/.mnemo/config.yaml`

```yaml
identity:
  name: "your-name"
  default_project: "my-project"
  agent: "claude-code"

team:
  cloud_url: "https://cloud.mnemo.dev"
  api_key: "your-key"
  team_id: "my-team"
  realtime_enabled: true     # SSE real-time sync
  auto_pull_enabled: true    # Auto-pull on teammate push

embeddings:
  provider: "ollama"         # or "openai", "http://..."
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `MNEMO_DATA_DIR` | `~/.mnemo` | Data directory |
| `MNEMO_PORT` | `7437` | HTTP server port |
| `MNEMO_AUTH_TOKEN` | (none) | Bearer token for HTTP auth |
| `MNEMO_EMBED` | (none) | Embedding provider |
| `MNEMO_CLOUD_URL` | (none) | Cloud sync endpoint |
| `MNEMO_TEAM_ID` | `default` | Team identifier |

## Project Configuration (`.mnemorc`)

A `.mnemorc` file in your project root lets you set Mnemo defaults per project. This means you do not need to pass `--project` on every command, and MCP tools automatically pick up the project context.

### Creating a `.mnemorc`

```bash
cd my-project
mnemo init
```

The `mnemo init` command launches an interactive TUI that guides you through configuring each field.

### Supported Fields

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | Project name (used as default for all commands) |
| `description` | string | Short project description |
| `team_id` | string | Team identifier for cloud sync |
| `embed` | string | Embedding provider override (e.g. `ollama:nomic-embed-text`) |
| `packs` | list | Packs to install for this project |
| `workflow` | string | Default workflow (e.g. `sdd`) |
| `skills` | list | Skills to make available |
| `persona` | string | Default persona |
| `tags` | list | Project tags for categorization |
| `privacy` | object | Privacy settings with `excluded_paths` and `excluded_types` |

### Example `.mnemorc`

```yaml
project: my-app
description: "Backend API service"
team_id: backend-team
embed: ollama
packs:
  - core
  - go
workflow: sdd
skills:
  - code-review
persona: mentor
tags:
  - golang
privacy:
  excluded_paths:
    - vendor/
    - .git/
  excluded_types:
    - config
```

### How Auto-Detection Works

Mnemo searches for `.mnemorc` starting from the current working directory and walking up the directory tree to the root. The first `.mnemorc` found is used. This means you can place the file in your project root, and it will be detected from any subdirectory.

When an MCP tool handler receives a request without an explicit `project` argument, it falls back to the project name from the detected `.mnemorc`. This applies to 9 MCP tool handlers.

The config is also auto-detected when `mnemo serve` starts, so the server knows the project context from launch.

## Uninstalling

```bash
# Remove from a specific agent
mnemo agent uninstall claude-code

# Remove from all agents (preserves data)
mnemo agent uninstall --mode full

# Remove everything including binary
mnemo agent uninstall --mode full-remove

# Factory reset (removes agents + data + binary)
mnemo agent uninstall --mode factory-reset

# Preview what would be removed
mnemo agent uninstall --dry-run
```

The default mode is data-preserving: `~/.mnemo/` (database, sessions) is
never deleted unless you explicitly use `--mode factory-reset` or pass `--purge-data`.

For Claude Code, uninstall:
- Removes MCP config entries (preserves other servers)
- Removes hooks from `settings.json` (preserves user hooks)
- Removes the `<!-- mnemo:memory-protocol -->` section from `CLAUDE.md` (preserves user content)
- Removes scripts and skills

## Backup and Recovery

```bash
# Config backups (hooks, scripts, skills)
mnemo backup list
mnemo backup restore <id>

# Pin important backups (protected from retention cleanup)
mnemo backup pin <id>
mnemo backup unpin <id>

# Data backup
mnemo export backup.json
mnemo import backup.json

# Export to Obsidian (markdown with wikilinks)
mnemo obsidian-export --output ~/vault/mnemo --project my-app
```

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture overview
- [API_REFERENCE.md](API_REFERENCE.md) — Complete API reference
- [MCP_AND_A2A_GUIDE.md](MCP_AND_A2A_GUIDE.md) — Protocol details
- [PACK_DEVELOPMENT.md](PACK_DEVELOPMENT.md) — How to create and publish packs
