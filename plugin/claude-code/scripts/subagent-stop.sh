#!/usr/bin/env bash
# Mnemo — SubagentStop hook for Claude Code
#
# Claude Code sends { session_id, cwd, stdout, ... } on stdin when a
# sub-agent finishes. We forward the sub-agent's output to the passive
# capture endpoint so the parent session can search through it later.
#
# MUST exit 0 always.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

INPUT=$(cat 2>/dev/null || true)
SESSION_ID=""
CWD=""
OUTPUT=""
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
  OUTPUT=$(printf '%s' "$INPUT" | jq -r '.stdout // empty' 2>/dev/null || true)
fi
if [ -z "$CWD" ]; then
  CWD=$(pwd)
fi

# Nothing to capture if the sub-agent produced no output.
[ -z "$OUTPUT" ] && exit 0

PROJECT=$(detect_project "$CWD")

# Best-effort passive capture. Truncate at 8 KB and let jq handle JSON escaping.
BODY=$(printf '%s' "$OUTPUT" | head -c 8192 | jq -Rs \
  --arg session_id "$SESSION_ID" \
  --arg project "$PROJECT" \
  '{type: "subagent_result", session_id: $session_id, project: $project, content: .}' 2>/dev/null || true)

if [ -n "$BODY" ]; then
  curl -sf --max-time 3 \
    -X POST "${MNEMO_URL}/memories/passive" \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    >/dev/null 2>&1 || true
fi

exit 0
