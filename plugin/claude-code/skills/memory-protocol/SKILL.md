---
name: mnemo-memory-protocol
description: "ALWAYS ACTIVE — Persistent memory protocol for Mnemo. You MUST save decisions, conventions, bugs, discoveries, and user preferences proactively. Do NOT wait for the user to ask. This is the behavioral contract that makes memory invisible and automatic."
---

# Mnemo Persistent Memory — Protocol

You have access to Mnemo, a persistent memory system that survives across sessions, compactions, and even across machines (via team sync). This protocol is MANDATORY and ALWAYS ACTIVE.

## AVAILABLE TOOLS

Core tools are loaded automatically at session start by the UserPromptSubmit hook.

- `mem_save` — Save a memory (decision, bugfix, pattern, discovery, etc.)
- `mem_search` — Hybrid search (full-text + semantic) across all memories
- `mem_context` — Get formatted context for current project/session
- `mem_get` — Retrieve full memory by ID
- `mem_update` — Update an existing memory
- `mem_delete` — Soft-delete a memory
- `mem_session_start` — Start a new session
- `mem_session_end` — End current session
- `mem_session_summary` — Save session summary (MANDATORY at session end)
- `mem_save_prompt` — Save user prompt for reference
- `mem_suggest_topic` — Get suggested topic_key for a memory
- `mem_timeline` — View memories around a specific point in time
- `skill_load` — Load a skill by name from installed packs

**Fallback**: If tools are unexpectedly unavailable, trigger ToolSearch:
```
select:mcp__mnemo__mem_save,mcp__mnemo__mem_search,mcp__mnemo__mem_context,mcp__mnemo__mem_session_summary,mcp__mnemo__mem_get,mcp__mnemo__mem_update,mcp__mnemo__mem_session_start,mcp__mnemo__mem_session_end,mcp__mnemo__mem_save_prompt,mcp__mnemo__mem_suggest_topic,mcp__mnemo__skill_load
```

## PROACTIVE SAVE TRIGGERS (mandatory — do NOT wait for user to ask)

Call `mem_save` IMMEDIATELY and WITHOUT BEING ASKED after any of these:

### After decisions or conventions
- Architecture or design decision made → type: `decision` or `architecture`
- Team convention documented or established → type: `pattern`
- Tool, library, or framework choice made with tradeoffs → type: `decision`
- Workflow change agreed upon → type: `decision`

### After completing work
- Bug fix completed (include root cause + solution) → type: `bugfix`
- Feature implemented with non-obvious approach → type: `discovery`
- Configuration change or environment setup → type: `config`
- Significant refactoring completed → type: `architecture`

### After discoveries
- Non-obvious behavior found in codebase → type: `discovery`
- Gotcha, edge case, or unexpected behavior → type: `discovery`
- Reusable pattern established → type: `pattern`
- Performance insight or optimization found → type: `discovery`

### After user confirmation or rejection
- User confirms a recommendation → type: `decision`
  (triggers: "yes", "dale", "go with that", "sounds good", "agreed", "vamos con eso", "let's do that")
- User rejects an option → type: `decision`
  (triggers: "no", "better X", "not that one", "descartemos eso", "quiero algo diferente")
- User expresses a preference → type: `preference`
  (triggers: "I prefer X", "always do X", "siempre hacé X", "me gusta más así")
- User makes a decision after tradeoff discussion → type: `decision`

### Self-check — ask yourself after EVERY task:
> "Did I or the user just make a decision, confirm something, fix a bug, learn something non-obvious, or establish a pattern? If yes → `mem_save` NOW."

## FORMAT FOR mem_save

```
mem_save(
  title:     "Verb + what"              # Short, searchable. e.g. "Fixed N+1 in UserList"
  type:      "bugfix"                   # bugfix|decision|architecture|discovery|pattern|config|preference|learning
  project:   "auto-detected"            # Usually auto-detected from CWD
  scope:     "project"                  # project (default) | personal | team
  topic_key: "domain/specific-topic"    # Enables upserts. e.g. "auth/session-strategy"
  content:   "## What\n...\n## Why\n...\n## Where\n...\n## Learned\n..."
)
```

### Topic update rules (mandatory)
- Different topics MUST NOT overwrite each other
- Same topic evolving → use same `topic_key` (Mnemo upserts automatically)
- If unsure about key → call `mem_suggest_topic` first
- If you know the exact memory ID → use `mem_update` instead

## WHEN TO SEARCH MEMORY

### Reactive (user asks)
When user says "remember", "recall", "what did we do", "how did we solve", "recordar", "acordate":
1. Call `mem_context` first (fast, recent history)
2. If not found → `mem_search` with relevant keywords
3. If match found → `mem_get` for full untruncated content

### Proactive (YOU search without being asked)
- Starting work on something → search for prior decisions on that topic
- Encountering an error → search for similar bugfixes
- User's first message references a feature/problem → search for context
- About to make an architectural decision → search for prior architecture memories
- Implementing a pattern → search for established patterns in this project

## SESSION LIFECYCLE

### Session start (handled by hook)
- Session created automatically
- Context loaded via `mem_context`
- Tools loaded via ToolSearch

### During session
- Save proactively per triggers above
- Search before major decisions
- The UserPromptSubmit hook will nudge you if >15 min without saving

### Session end (MANDATORY)
Before ending or saying "done"/"listo"/"that's it", you MUST call `mem_session_summary`:

```markdown
## Goal
[What we were working on this session]

## Accomplished
- [Completed items with key details]

## Decisions Made
- [Decisions with rationale — skip if none]

## Discoveries
- [Technical findings, gotchas — skip if none]

## Next Steps
- [What remains to be done]

## Relevant Files
- path/to/file — [what changed]
```

This is NOT optional. Skipping this means the next session starts blind.

## AFTER COMPACTION

If context is compacted:
1. IMMEDIATELY call `mem_session_summary` with the compacted summary (preserves it)
2. Call `mem_context` to recover additional context
3. If needed, `mem_search` for specific topics you were working on
4. Only THEN continue working

The post-compaction hook handles steps 2-4 automatically, but step 1 requires YOUR action.

## TEAM SYNC (if enabled)

When team sync is active (shown at session start):
- Memories with `scope: project` are synced to the team automatically
- Use `scope: personal` for personal preferences not relevant to team
- Use `scope: team` for cross-project knowledge
- Search with `sync_scope: team` to find teammates' knowledge
