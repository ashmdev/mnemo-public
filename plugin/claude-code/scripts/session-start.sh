#!/usr/bin/env bash
# Mnemo — SessionStart hook for Claude Code
#
# Claude Code writes a JSON payload to stdin with { session_id, cwd, source,
# hook_event_name, ... }. We:
#
#   1. Auto-start `mnemo serve` if not already running
#   2. Reuse Claude Code's own session_id as the Mnemo session id — this is
#      the SAME id every other hook (UserPromptSubmit / PreCompact / Stop)
#      and the transcript file on disk see, so everything stays consistent
#      across hooks, MCP tool calls, and the dashboard
#   3. Persist the id to a CWD-keyed handoff file so the MCP subprocess
#      (which is spawned separately and does NOT inherit our env) can pick
#      it up on the next `mem_save`
#   4. Output memory context and team sync status as additionalContext
#
# Sources Claude Code reports to this hook:
#   startup | resume | clear | compact
# For compact the session_id is unchanged; for clear/resume/startup it is a
# fresh UUID. In all cases the handoff write is idempotent and correct.
#
# MUST exit 0 always — stdout becomes Claude's additionalContext.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

MNEMO="${MNEMO_BIN:-mnemo}"

# ── Read hook payload from stdin ──────────────────────────────────────────────

INPUT=$(cat 2>/dev/null || true)
SESSION_ID=""
CWD=""
SOURCE=""
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
  SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null || true)
fi

# Fallback when run outside Claude Code (manual testing / stdin empty).
if [ -z "$CWD" ]; then
  CWD=$(pwd)
fi
if [ -z "$SESSION_ID" ]; then
  # Only reached when someone invokes the hook by hand. Real Claude Code runs
  # always provide a uuid. We still need a unique id so mem_save has something
  # to attach to.
  SESSION_ID="cc-$(date +%Y%m%d-%H%M%S)-$$"
fi

# ── Auto-start mnemo serve if not running ─────────────────────────────────────

if ! check_health; then
  "${MNEMO}" serve &
  disown

  # Wait for server readiness (up to 10 seconds).
  for i in $(seq 1 20); do
    if check_health; then break; fi
    sleep 0.5
  done

  # If still not ready, output minimal context and exit gracefully.
  if ! check_health; then
    echo "Mnemo server not available. Memory features disabled for this session."
    echo "Start manually with: mnemo serve"
    exit 0
  fi
fi

# ── Create session ────────────────────────────────────────────────────────────

PROJECT=$(detect_project "$CWD")

api_post "/sessions" \
  "{\"id\":\"${SESSION_ID}\",\"project\":\"${PROJECT}\",\"directory\":\"${CWD}\",\"agent\":\"claude-code\"}" \
  >/dev/null

# Persist the session ID to a handoff file keyed by CWD. The MCP subprocess
# launched by Claude Code does not share our process environment, so it
# reads this file on its next tool call to bind mem_save() to the correct
# session. Every hook source (startup | resume | clear | compact) triggers
# an idempotent write: for compact the id is unchanged and the rewrite is
# a no-op; for the others the new id correctly overwrites any stale entry.
write_session_handoff "${SESSION_ID}" "${CWD}"

# ── Output Memory Protocol + context for Claude ──────────────────────────────
# stdout becomes additionalContext — Claude receives this as system context
# at session start. This is the PRIMARY compliance mechanism.

cat <<'PROTOCOL'
## Mnemo Persistent Memory — ACTIVE PROTOCOL

You have mnemo memory tools. This protocol is MANDATORY and ALWAYS ACTIVE.

### CORE TOOLS — always available, no ToolSearch needed
mem_save, mem_search, mem_context, mem_session_summary, mem_get, mem_save_prompt

### PROACTIVE SAVE — do NOT wait for user to ask
Call `mem_save` IMMEDIATELY after ANY of these:
- Decision made (architecture, convention, tool choice, tradeoffs)
- Bug fixed (include root cause in content)
- Non-obvious discovery, gotcha, or edge case found
- Pattern established (naming, structure, approach)
- User preference or constraint learned
- Feature implemented with non-obvious approach
- User confirms your recommendation ("yes", "go with that", "sounds good")
- User rejects an approach ("no", "better X", "I prefer X")
- Discussion concludes with a clear direction chosen

**Self-check after EVERY task**: "Did something worth remembering just happen? If yes → mem_save NOW."

Format: title="Verb + what", type=bugfix|decision|discovery|pattern|preference, topic_key="category/topic"
Content: **What** (done), **Why** (motivation), **Where** (files), **Learned** (gotchas)

### SEARCH MEMORY when:
- Starting work on something that might have been done before
- User mentions a topic you have no context on
- User asks to recall anything ("remember", "what did we do")

### SESSION CLOSE — before saying "done":
Call `mem_session_summary` with: Goal, Discoveries, Accomplished, Next Steps.
This is NOT optional. Without it, the next session starts blind.

### ADDITIONAL TOOLS (use ToolSearch to discover):
skill_load, skill_recommend, workflow_phases, mem_graph_query, mem_export_obsidian
PROTOCOL

CONTEXT=$("${MNEMO}" context "${PROJECT}" 2>/dev/null || true)
if [ -n "$CONTEXT" ]; then
  printf '\n---\n%s\n' "$CONTEXT"
fi

# ── Show sync status if team sync is enabled ──────────────────────────────────

SYNC_STATUS=$(api_get "/sync/status" 2>/dev/null)
if [ -n "$SYNC_STATUS" ]; then
  SYNC_ENABLED=$(echo "$SYNC_STATUS" | jq -r '.enabled // false' 2>/dev/null)
  if [ "$SYNC_ENABLED" = "true" ]; then
    CLOUD_URL=$(echo "$SYNC_STATUS" | jq -r '.cloud_url // empty' 2>/dev/null)
    CONNECTED=$(echo "$SYNC_STATUS" | jq -r '.connected // false' 2>/dev/null)
    if [ "$CONNECTED" = "true" ]; then
      printf '\n🔄 Team sync active: %s\n' "${CLOUD_URL:-connected}"
    else
      printf '\n🔄 Team sync configured but offline: %s\n' "${CLOUD_URL:-unknown}"
    fi
  fi
fi

exit 0
