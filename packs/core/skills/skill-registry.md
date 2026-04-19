# Core: Skill Registry — Compact Rules Generator

## Purpose

Generate an indexed catalog of all installed skills with pre-digested compact rules
(5-15 lines each). This registry is built once (expensive), then read cheaply at every
delegation. Sub-agents receive compact rules — never full SKILL.md files — saving
tokens while preserving quality.

## When to Use

- User says "update skills", "skill registry", "actualizar skills", "update registry"
- After installing or removing skill packs (`mnemo pack install`)
- After setting up a new project
- As part of `sdd-init`
- When skill-resolver reports stale or missing registry

## When NOT to Use

- This is an index-building step, not a code execution step
- Don't run this during active coding — it reads many files

## Instructions

### Step 1: Scan All Installed Skills

Scan for SKILL.md or `*.md` skill files across ALL known locations:

**User-level (global skills):**
- `~/.claude/skills/` — Claude Code
- `~/.config/opencode/skills/` — OpenCode
- `~/.gemini/skills/` — Gemini CLI
- `~/.cursor/skills/` — Cursor
- `~/.copilot/skills/` — VS Code Copilot
- `~/.windsurf/skills/` — Windsurf

**Project-level (workspace skills):**
- `{project-root}/.claude/skills/`
- `{project-root}/.gemini/skills/`
- `{project-root}/skills/`

**Mnemo packs (UNIQUE TO MNEMO):**
Search Mnemo for installed pack skills:
```
mem_search(query: "skill", type: "skill", limit: 50)
```

Also check local pack directories if accessible.

**Skip:**
- `sdd-*` (SDD workflow skills — separate lifecycle)
- `_shared/` (shared conventions, not standalone skills)
- `skill-registry` (this skill)
- `memory-protocol` (always-active, not delegatable)

**Deduplicate:** If the same skill name appears in multiple locations, prefer:
1. Project-level (most specific)
2. Mnemo pack version
3. User-level (global)

### Step 2: Generate Compact Rules

For each skill found, read the full content and generate a compact rules block.

**Compact rules must be 5-15 lines containing ONLY:**
- Actionable rules and constraints ("do X", "never Y", "prefer Z over W")
- Key patterns with one-line examples where critical
- Breaking changes or gotchas that would cause bugs if missed

**DO NOT include:** purpose, motivation, when-to-use, installation steps, full examples.

**Format per skill:**
```markdown
### {skill-name}
- Rule 1
- Rule 2
- ...
```

**Example — compact rules for a React 19 skill:**
```markdown
### react-19
- No useMemo/useCallback — React Compiler handles memoization
- use() hook for promises/context, replaces useEffect for data fetching
- Server Components by default, add 'use client' only for interactivity
- ref is a regular prop — no forwardRef needed
- Actions: useActionState for form mutations, useOptimistic for optimistic UI
```

**The compact rules are the MOST IMPORTANT output.** They are what sub-agents receive. Invest time making them accurate and concise.

### Step 3: Scan Project Conventions

Check the project root for convention files:
- `CLAUDE.md` (project-level only, not `~/.claude/CLAUDE.md`)
- `.cursorrules`
- `GEMINI.md`
- `AGENTS.md` or `agents.md`
- `copilot-instructions.md`

If an index file is found (e.g., `AGENTS.md`): read its contents and extract all
referenced file paths. Include both the index file AND all referenced paths.

### Step 4: Write the Registry

Build and write `.mnemo/skill-registry.md` in the project root:

```markdown
# Skill Registry

**Delegator use only.** Orchestrators read this registry to resolve compact rules,
then inject them into sub-agent prompts. Sub-agents do NOT read this file.

## Skills

| Trigger | Skill | Source | Path |
|---------|-------|--------|------|
| {trigger from description} | {name} | {pack/user/project} | {path} |

## Compact Rules

Pre-digested rules per skill. Delegators copy matching blocks into sub-agent
prompts as `## Project Standards (auto-resolved)`.

### {skill-name-1}
- Rule 1
- Rule 2

### {skill-name-2}
- Rule 1
- Rule 2

## Project Conventions

| File | Path | Notes |
|------|------|-------|
| {file} | {path} | {context} |
```

### Step 5: Persist to Mnemo Memory

**Always write the file** (guaranteed availability):
```bash
mkdir -p .mnemo && write .mnemo/skill-registry.md
```

**Also save to Mnemo** (cross-session, survives directory changes):
```
mem_save(
  title: "skill-registry",
  topic_key: "skill-registry",
  type: "config",
  project: "{project}",
  scope: "project",
  content: "{full registry markdown}"
)
```

`topic_key: "skill-registry"` ensures upserts — running again updates the same memory.

Add `.mnemo/` to `.gitignore` if not already listed.

### Step 6: Report

```markdown
## Skill Registry Updated

**Project**: {name}
**Location**: .mnemo/skill-registry.md
**Mnemo**: {saved / not available}

### Skills Found: {N}
| Skill | Source | Compact Rules |
|-------|--------|---------------|
| {name} | {source} | {line count} lines |

### Conventions Found: {N}
| File | Path |
|------|------|
| {name} | {path} |

### Next Steps
The skill-resolver protocol uses this registry for automatic skill matching.
Re-run after installing or removing skill packs.
```

## Graceful Degradation

- If Mnemo is unavailable → write file only, skip `mem_save`
- If no skills found → write empty registry (prevents futile searches)
- If project root undetectable → write to current directory
