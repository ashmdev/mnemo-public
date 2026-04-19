#!/usr/bin/env bash
# Mnemo — Post-Compaction Recovery hook for Claude Code
#
# When Claude Code compacts the context window, everything before compaction
# is summarized and the detailed history is lost. This hook recovers persistent
# state from Mnemo so the agent doesn't start blind.
#
# Reads { session_id, cwd } from stdin. After /compact, Claude Code keeps the
# SAME session_id (only /clear and /resume rotate it), so we just re-assert
# the handoff file in case it was removed/stale and continue the recovery
# protocol.
#
# 4-step recovery protocol:
#   1. Save a session summary of the compacted content
#   2. Reload full project context via mem_context
#   3. Inject the Memory Protocol so agent continues saving proactively
#   4. Instruct agent to search if specific context is missing
#
# MUST exit 0 always — output becomes Claude's additionalContext.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

INPUT=$(cat 2>/dev/null || true)
SESSION_ID=""
CWD=""
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
if [ -z "$CWD" ]; then
  CWD=$(pwd)
fi

PROJECT="${CLAUDE_PROJECT:-$(detect_project "$CWD")}"

# Re-assert the session handoff so the MCP subprocess can always find it,
# even if the handoff file got cleaned up between the start of the session
# and compaction. No-op if SESSION_ID is empty (manual invocation).
if [ -n "$SESSION_ID" ]; then
  write_session_handoff "$SESSION_ID" "$CWD"
fi

# ── Step 1: Output recovery instructions ─────────────────────────────────────
# These become Claude's additionalContext after compaction.

cat <<'RECOVERY_PROTOCOL'
## ⚠️ CONTEXT COMPACTED — Recovery Protocol (MANDATORY)

Your context was just compacted. Follow these steps IN ORDER:

### Step 1: Persist the compacted summary
Call `mem_session_summary` with the summary content you received from compaction.
This preserves what was accomplished before compaction.

### Step 2: Reload project context
Call `mem_context` to recover session history and recent memories.

### Step 3: Search for specific context
If you were working on something specific and mem_context didn't recover it:
- Call `mem_search` with keywords from what you were doing
- Call `mem_get` for any memory IDs returned

### Step 4: Continue working
After recovery, continue where you left off. The Memory Protocol below
remains active — keep saving proactively.

RECOVERY_PROTOCOL

# ── Step 2: Output fresh project context ──────────────────────────────────────

if check_health; then
  CONTEXT=$("${MNEMO_BIN:-mnemo}" context "${PROJECT}" 2>/dev/null || true)
  if [ -n "$CONTEXT" ]; then
    printf '\n## Recovered Context\n\n%s\n' "$CONTEXT"
  fi
fi

# ── Step 3: Re-inject Memory Protocol (condensed) ────────────────────────────

cat <<'MEMORY_PROTOCOL'

## Memory Protocol (ALWAYS ACTIVE)

Save proactively after: decisions, bug fixes, discoveries, patterns, user confirmations/rejections.
Format: title (verb+what), type (bugfix|decision|pattern|discovery|config|preference|architecture), topic_key for evolving topics.
Search before: starting new work, making decisions, encountering unfamiliar code.
Session end: ALWAYS call mem_session_summary before finishing.

MEMORY_PROTOCOL

exit 0
