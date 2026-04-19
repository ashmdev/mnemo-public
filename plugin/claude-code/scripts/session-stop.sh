#!/usr/bin/env bash
# Mnemo — Stop hook for Claude Code
#
# Claude Code sends { session_id, cwd, transcript_path, ... } on stdin.
#
# Two jobs:
#   1. End the session via HTTP API
#   2. AUTO-SAVE: Read the transcript file to extract what was done and save
#      a session memory automatically — NO model cooperation needed.
#
# MUST exit 0 always.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

INPUT=$(cat 2>/dev/null || true)
SESSION_ID=""
CWD=""
TRANSCRIPT_PATH=""
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
  TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
fi
if [ -z "$CWD" ]; then
  CWD=$(pwd)
fi

PROJECT=$(detect_project "${CWD}")

# ── Auto-save session summary from transcript ────────────────────────────────
# Read the transcript JSONL file to extract what was worked on.
# This runs BEFORE ending the session so the memory gets the correct session_id.

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ] && [ -n "$SESSION_ID" ] && check_health; then
  # Extract info from JSONL transcript using grep (more reliable than jq for nested structures).
  # Claude Code JSONL format: each line is a JSON object with "type" field.
  # User messages: {"type":"user","message":{"content":"..."}}
  # Tool uses: embedded in assistant messages as {"type":"tool_use","name":"Write",...}
  FIRST_USER=$(grep -m1 '"type":"user"' "$TRANSCRIPT_PATH" 2>/dev/null | jq -r '.message.content // empty' 2>/dev/null | head -c 200)
  TOOL_COUNT=$(grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
  FILES_WRITTEN=$(grep -c '"Write"\|"Edit"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)

  # Only save if there was actual work (not just a greeting)
  if [ -n "$FIRST_USER" ] && [ "$TOOL_COUNT" -gt 0 ]; then
    SUMMARY="Session auto-captured by Mnemo.

**Goal**: ${FIRST_USER}
**Tools used**: ${TOOL_COUNT}
**Files written/edited**: ${FILES_WRITTEN}
**Project**: ${PROJECT}"

    TITLE="Session: $(printf '%s' "$FIRST_USER" | head -c 60)"

    BODY=$(jq -n \
      --arg title "$TITLE" \
      --arg content "$SUMMARY" \
      --arg type "session" \
      --arg session_id "$SESSION_ID" \
      --arg project "$PROJECT" \
      --arg scope "project" \
      --arg topic_key "session/auto-capture" \
      '{title: $title, content: $content, type: $type, session_id: $session_id, project: $project, scope: $scope, topic_key: $topic_key}' 2>/dev/null)

    if [ -n "$BODY" ]; then
      curl -sf --max-time 3 \
        -X POST "${MNEMO_URL}/memories" \
        -H "Content-Type: application/json" \
        -d "$BODY" \
        >/dev/null 2>&1 || true
    fi
  fi
fi

# ── End session ──────────────────────────────────────────────────────────────

if [ -n "$SESSION_ID" ]; then
  curl -sf --max-time 2 \
    -X POST "${MNEMO_URL}/sessions/${SESSION_ID}/end" \
    -H "Content-Type: application/json" \
    -d '{}' \
    >/dev/null 2>&1 || true
fi

# Drop the session-handoff file so the next session from the same CWD starts fresh.
clear_session_handoff "${CWD}"

exit 0
