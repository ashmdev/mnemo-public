#!/usr/bin/env bash
# Mnemo — UserPromptSubmit hook for Claude Code
#
# On the FIRST message of a session: injects ToolSearch instruction to force
# Claude Code to load all mnemo memory tools (which may be deferred).
# Also calls mem_context to load prior session history.
#
# On subsequent messages: checks when the last mem_save was for the current
# project. If it's been > 15 minutes AND the session has been active > 5
# minutes, injects a SMART nudge that suggests what TYPE of memory to save
# based on context (not just a generic "save something").
#
# IMPROVEMENT over engram: Smart nudge suggests type + topic_key, not generic.
#
# MUST exit 0 always and output valid JSON — otherwise Claude Code blocks the message.

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

# Read hook input from stdin (Claude Code sends JSON with cwd, session_id, prompt, etc.)
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
PROJECT=$(detect_project "${CWD:-.}")

# Default: no injection
OUTPUT="{}"

# ──────────────────────────────────────────────────────────────────────────────
# AUTO-SAVE USER PROMPT (fire-and-forget, no model cooperation needed)
#
# Every user message is saved as a prompt in Mnemo. This creates a timeline
# of what the user worked on, even if the model never calls mem_save.
# ──────────────────────────────────────────────────────────────────────────────

if [ -n "$PROMPT" ] && [ -n "$SESSION_ID" ] && check_health; then
  # Truncate to 4KB to avoid huge pastes
  TRUNCATED=$(printf '%s' "$PROMPT" | head -c 4096)
  BODY=$(jq -n \
    --arg session_id "$SESSION_ID" \
    --arg content "$TRUNCATED" \
    --arg project "$PROJECT" \
    '{session_id: $session_id, content: $content, project: $project}' 2>/dev/null)
  if [ -n "$BODY" ]; then
    curl -sf --max-time 1 \
      -X POST "${MNEMO_URL}/prompts" \
      -H "Content-Type: application/json" \
      -d "$BODY" \
      >/dev/null 2>&1 &
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# FIRST-MESSAGE DETECTION
#
# State file in /tmp keyed by session_id. Ensures ToolSearch only fires once.
# ──────────────────────────────────────────────────────────────────────────────

if [ -n "$SESSION_ID" ]; then
  SESSION_KEY="mnemo-claude-${SESSION_ID}-tools-loaded"
else
  SAFE_PROJECT=$(printf '%s' "${PROJECT:-unknown}" | tr -cs 'a-zA-Z0-9_-' '_')
  SESSION_KEY="mnemo-claude-${SAFE_PROJECT}-$$-tools-loaded"
fi

STATE_FILE="/tmp/${SESSION_KEY}"

if [ ! -f "$STATE_FILE" ]; then
  # ── FIRST MESSAGE ──────────────────────────────────────────────────────────
  touch "$STATE_FILE" 2>/dev/null || true

  # Force load core mnemo tools + check for prior session context.
  TOOL_MSG="CRITICAL FIRST ACTION — Execute this ToolSearch NOW before responding to the user:
select:mcp__mnemo__mem_save,mcp__mnemo__mem_search,mcp__mnemo__mem_context,mcp__mnemo__mem_session_summary,mcp__mnemo__mem_get,mcp__mnemo__mem_update,mcp__mnemo__mem_session_start,mcp__mnemo__mem_session_end,mcp__mnemo__mem_save_prompt,mcp__mnemo__mem_suggest_topic,mcp__mnemo__skill_load

After loading tools, call mem_context to check for prior session history before responding.
If this is a known project, search for recent decisions and patterns relevant to the user's request."

  OUTPUT=$(jq -n --arg msg "$TOOL_MSG" '{"systemMessage": $msg}')
  printf '%s\n' "$OUTPUT"
  exit 0
fi

# ──────────────────────────────────────────────────────────────────────────────
# SUBSEQUENT MESSAGES — Smart save-nudge logic
# ──────────────────────────────────────────────────────────────────────────────

# Bail early if server unreachable or project unknown.
if [ -z "$PROJECT" ] || ! check_health; then
  json_output "$OUTPUT"
  exit 0
fi

# Check session age — skip nudge if session < 5 minutes old.
if [ -n "$SESSION_ID" ]; then
  SESSION_JSON=$(api_get "/sessions/${SESSION_ID}")
  if [ -n "$SESSION_JSON" ]; then
    SESSION_START=$(echo "$SESSION_JSON" | jq -r '.started_at // empty' 2>/dev/null)
    if [ -n "$SESSION_START" ]; then
      SESSION_START_EPOCH=$(parse_iso_epoch "$SESSION_START")
      NOW_EPOCH=$(epoch_now)
      SESSION_AGE=$(( NOW_EPOCH - SESSION_START_EPOCH ))
      if [ "$SESSION_AGE" -lt 300 ]; then
        json_output "$OUTPUT"
        exit 0
      fi
    fi
  fi
fi

# Fetch most recent memory for this project.
ENCODED_PROJECT=$(printf '%s' "$PROJECT" | jq -sRr @uri)
LAST_SAVE_JSON=$(api_get "/memories/recent?project=${ENCODED_PROJECT}&limit=1")

if [ -z "$LAST_SAVE_JSON" ]; then
  json_output "$OUTPUT"
  exit 0
fi

LAST_SAVE_AT=$(echo "$LAST_SAVE_JSON" | jq -r '.[0].created_at // empty' 2>/dev/null)

if [ -z "$LAST_SAVE_AT" ]; then
  # No memories yet for this project — no nudge (session might be fresh).
  json_output "$OUTPUT"
  exit 0
fi

# Compare timestamps — nudge if last save > 15 minutes ago (900 seconds).
LAST_EPOCH=$(parse_iso_epoch "$LAST_SAVE_AT")
NOW_EPOCH=$(epoch_now)
ELAPSED=$(( NOW_EPOCH - LAST_EPOCH ))

if [ "$ELAPSED" -gt 900 ]; then
  MINUTES=$(( ELAPSED / 60 ))
  NUDGE_MSG="MEMORY NUDGE: It's been ${MINUTES} minutes since your last save for project '${PROJECT}'.

If you've done any of these, call mem_save NOW:
- Made a decision or chose between options → type: decision
- Fixed a bug or resolved an error → type: bugfix
- Discovered something non-obvious about the code → type: discovery
- Established or followed a pattern → type: pattern
- Changed configuration or setup → type: config
- Learned a user preference → type: preference

Use a descriptive title (verb + what) and include topic_key for evolving topics."

  OUTPUT=$(jq -n --arg msg "$NUDGE_MSG" '{"systemMessage": $msg}')
fi

json_output "$OUTPUT"
exit 0
