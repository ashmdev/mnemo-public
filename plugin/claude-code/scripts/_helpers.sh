#!/usr/bin/env bash
# Mnemo — Shared helper functions for Claude Code hooks.
# Sourced by all hook scripts. Never executed directly.

MNEMO_PORT="${MNEMO_PORT:-7437}"
MNEMO_HOST="${MNEMO_HOST:-127.0.0.1}"
MNEMO_URL="http://${MNEMO_HOST}:${MNEMO_PORT}"
MNEMO_DATA_DIR="${MNEMO_DATA_DIR:-$HOME/.mnemo}"
MNEMO_SESSION_HANDOFF_DIR="${MNEMO_DATA_DIR}/sessions/by-cwd"

# cwd_hash — Stable 16-hex-char hash of an absolute path.
# Both bash hooks and the Go MCP read the same hash for a given CWD so they
# can agree on which session-handoff file to use.
cwd_hash() {
  local path
  path=$(cd "${1:-.}" 2>/dev/null && pwd -P) || path="${1:-.}"
  # shasum is posix-ish (ships on macOS + Linux); sha256sum as fallback.
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$path" | shasum -a 256 | cut -c1-16
  else
    printf '%s' "$path" | sha256sum | cut -c1-16
  fi
}

# write_session_handoff — Persist the active session ID for a given CWD so
# that the MCP subprocess (which does NOT inherit env vars from this hook)
# can pick it up via resolveSession(). Writes atomically via rename.
#
# Two files are written:
#
#   <handoff_dir>/<cwd_hash>.txt
#       Primary handoff keyed by the hash of the absolute CWD. The MCP
#       subprocess tries this first by hashing its own os.Getwd().
#
#   <handoff_dir>/latest.txt
#       Fallback for clients that spawn the MCP subprocess with a CWD that
#       does NOT match what the hook sees — notably Claude Desktop on
#       macOS, which launches subprocesses from `/`. The MCP reads this
#       file with a short TTL if the cwd-hash lookup misses, so a session
#       fresh from the current SessionStart hook still wins.
write_session_handoff() {
  local session_id="$1"
  local cwd="${2:-.}"
  [ -z "$session_id" ] && return 0
  mkdir -p "$MNEMO_SESSION_HANDOFF_DIR" 2>/dev/null || return 0

  local hash
  hash=$(cwd_hash "$cwd")

  _write_handoff_file "${MNEMO_SESSION_HANDOFF_DIR}/${hash}.txt" "$session_id"
  _write_handoff_file "${MNEMO_SESSION_HANDOFF_DIR}/latest.txt"  "$session_id"
}

# _write_handoff_file — Internal: atomic write of a one-line session id to
# a target path. No-op on any filesystem error (handoff is best-effort).
_write_handoff_file() {
  local target="$1"
  local session_id="$2"
  local tmp="${target}.$$"
  printf '%s\n' "$session_id" > "$tmp" 2>/dev/null || return 0
  mv -f "$tmp" "$target" 2>/dev/null || rm -f "$tmp" 2>/dev/null
}

# clear_session_handoff — Remove the handoff files for the given CWD.
# Called from session-stop.sh so stale handoffs do not leak into future
# sessions. Clears both the cwd-keyed file AND latest.txt so a subsequent
# client with CWD=/ does not pick up the id from a chat that already ended.
clear_session_handoff() {
  local cwd="${1:-.}"
  local hash
  hash=$(cwd_hash "$cwd")
  rm -f "${MNEMO_SESSION_HANDOFF_DIR}/${hash}.txt" 2>/dev/null || true
  rm -f "${MNEMO_SESSION_HANDOFF_DIR}/latest.txt"  2>/dev/null || true
}

# walk_up_mnemorc — Walk up from dir looking for .mnemorc and print its project.
# Returns the project name on stdout, empty string if not found or invalid.
# Matches the Go-side lookup in internal/service/projectconfig.go.
walk_up_mnemorc() {
  local dir
  dir=$(cd "${1:-.}" 2>/dev/null && pwd) || return 0

  while [ -n "$dir" ]; do
    local candidate="${dir}/.mnemorc"
    if [ -f "$candidate" ]; then
      # Extract the project field. Must match Go regex: ^[a-z][a-z0-9._-]{0,63}$
      # YAML format: `project: name` (with optional surrounding whitespace, no quotes).
      local project
      project=$(awk '
        /^[[:space:]]*project[[:space:]]*:[[:space:]]*/ {
          sub(/^[[:space:]]*project[[:space:]]*:[[:space:]]*/, "")
          sub(/[[:space:]]*#.*$/, "")       # strip trailing comments
          gsub(/^["'\'']|["'\'']$/, "")     # strip surrounding quotes
          gsub(/[[:space:]]+$/, "")         # strip trailing whitespace
          print
          exit
        }
      ' "$candidate" 2>/dev/null)

      # Validate against the same regex the Go code uses.
      if [ -n "$project" ] && printf '%s' "$project" | grep -Eq '^[a-z][a-z0-9._-]{0,63}$'; then
        printf '%s' "$project"
        return 0
      fi
      # Found .mnemorc but project invalid/missing — stop walking, fall through to git.
      return 0
    fi

    local parent
    parent=$(dirname "$dir")
    if [ "$parent" = "$dir" ]; then
      break
    fi
    dir="$parent"
  done
}

# detect_project — Derive project name from CWD.
#   1. .mnemorc walk-up (explicit, versionable, team-shared) — SAME as Go logic
#   2. Git remote origin URL (handles ssh:// and https://)
#   3. Git worktree root (works in subdirs and worktrees)
#   4. Current directory basename (fallback)
detect_project() {
  local dir="${1:-.}"

  # Try .mnemorc first (explicit user choice, matches Go-side lookup).
  local from_mnemorc
  from_mnemorc=$(walk_up_mnemorc "$dir")
  if [ -n "$from_mnemorc" ]; then
    printf '%s' "$from_mnemorc"
    return 0
  fi

  # Try git remote (most accurate cross-machine).
  local remote
  remote=$(cd "$dir" 2>/dev/null && git remote get-url origin 2>/dev/null) || true
  if [ -n "$remote" ]; then
    # Strip .git suffix, then take last path segment.
    remote="${remote%.git}"
    printf '%s' "${remote##*/}"
    return 0
  fi

  # Try git root directory name (works in worktrees/subdirs).
  local root
  root=$(cd "$dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || true
  if [ -n "$root" ]; then
    printf '%s' "$(basename "$root")"
    return 0
  fi

  # Fallback: CWD basename.
  printf '%s' "$(basename "$(cd "$dir" && pwd)")"
}

# check_health — Returns 0 if mnemo server is reachable.
check_health() {
  curl -sf --max-time 1 "${MNEMO_URL}/health" >/dev/null 2>&1
}

# api_get — GET request to mnemo API. Returns body on success, empty on failure.
api_get() {
  local path="$1"
  curl -sf --max-time 2 "${MNEMO_URL}${path}" 2>/dev/null || true
}

# api_post — POST JSON to mnemo API. Returns body on success, empty on failure.
api_post() {
  local path="$1"
  local body="$2"
  curl -sf --max-time 3 \
    -X POST "${MNEMO_URL}${path}" \
    -H "Content-Type: application/json" \
    -d "$body" 2>/dev/null || true
}

# json_output — Safely produce JSON output for Claude Code hooks.
#   Usage: json_output '{"key": "value"}'
#   Ensures valid JSON on stdout even if something goes wrong.
json_output() {
  printf '%s\n' "${1:-{}}"
}

# epoch_now — Current Unix timestamp (portable across macOS and Linux).
epoch_now() {
  date "+%s"
}

# parse_iso_epoch — Convert ISO 8601 timestamp to Unix epoch.
#   Handles both macOS (date -j) and Linux (date -d) syntax.
parse_iso_epoch() {
  local ts="${1%%.*}"  # Strip fractional seconds
  ts="${ts%%Z}"        # Strip Z suffix
  # macOS
  date -j -f "%Y-%m-%dT%H:%M:%S" "$ts" "+%s" 2>/dev/null && return 0
  # Linux
  date -d "$ts" "+%s" 2>/dev/null && return 0
  # Fallback
  echo "0"
}
