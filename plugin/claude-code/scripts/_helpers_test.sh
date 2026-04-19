#!/usr/bin/env bash
# Mnemo — Tests for _helpers.sh (detect_project + walk_up_mnemorc).
# Run: bash _helpers_test.sh
#
# Uses isolated temp directories so nothing leaks into the real filesystem.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

PASS=0
FAIL=0
FAILED_TESTS=()

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  ✓ %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    FAILED_TESTS+=("$name")
    printf '  ✗ %s\n    expected: %q\n    actual:   %q\n' "$name" "$expected" "$actual"
  fi
}

# Create an isolated sandbox rooted under $TMPDIR.
TMP_ROOT=$(mktemp -d -t mnemo_helpers_test.XXXXXX)
trap 'rm -rf "$TMP_ROOT"' EXIT

printf '\n=== walk_up_mnemorc ===\n'

# Test 1: no .mnemorc anywhere → empty
mkdir -p "${TMP_ROOT}/empty/deep/nested"
assert_eq "no .mnemorc returns empty" "" "$(walk_up_mnemorc "${TMP_ROOT}/empty/deep/nested")"

# Test 2: .mnemorc in immediate dir with valid project
mkdir -p "${TMP_ROOT}/direct"
cat > "${TMP_ROOT}/direct/.mnemorc" <<EOF
project: mnemo
EOF
assert_eq ".mnemorc in direct dir" "mnemo" "$(walk_up_mnemorc "${TMP_ROOT}/direct")"

# Test 3: .mnemorc walk-up from nested subdirectory
mkdir -p "${TMP_ROOT}/walkup/a/b/c"
cat > "${TMP_ROOT}/walkup/.mnemorc" <<EOF
project: myproj
EOF
assert_eq "walk-up 3 levels" "myproj" "$(walk_up_mnemorc "${TMP_ROOT}/walkup/a/b/c")"

# Test 4: inner .mnemorc shadows outer
mkdir -p "${TMP_ROOT}/shadow/inner"
cat > "${TMP_ROOT}/shadow/.mnemorc" <<EOF
project: outer
EOF
cat > "${TMP_ROOT}/shadow/inner/.mnemorc" <<EOF
project: inner
EOF
assert_eq "inner shadows outer" "inner" "$(walk_up_mnemorc "${TMP_ROOT}/shadow/inner")"

# Test 5: project with dots, dashes, numbers
mkdir -p "${TMP_ROOT}/special"
cat > "${TMP_ROOT}/special/.mnemorc" <<EOF
project: my-proj.v2_0
EOF
assert_eq "valid chars (dot/dash/underscore/digit)" "my-proj.v2_0" "$(walk_up_mnemorc "${TMP_ROOT}/special")"

# Test 6: project with surrounding whitespace
mkdir -p "${TMP_ROOT}/ws"
cat > "${TMP_ROOT}/ws/.mnemorc" <<EOF
project:    spaced
EOF
assert_eq "whitespace tolerated" "spaced" "$(walk_up_mnemorc "${TMP_ROOT}/ws")"

# Test 7: project with trailing comment
mkdir -p "${TMP_ROOT}/comment"
cat > "${TMP_ROOT}/comment/.mnemorc" <<EOF
project: hello # my project
EOF
assert_eq "trailing comment stripped" "hello" "$(walk_up_mnemorc "${TMP_ROOT}/comment")"

# Test 8: other yaml fields before project
mkdir -p "${TMP_ROOT}/multi"
cat > "${TMP_ROOT}/multi/.mnemorc" <<EOF
description: something
project: multi
team_id: abc
EOF
assert_eq "project among other fields" "multi" "$(walk_up_mnemorc "${TMP_ROOT}/multi")"

# Test 9: invalid project (uppercase) → empty (doesn't match Go regex)
mkdir -p "${TMP_ROOT}/invalid"
cat > "${TMP_ROOT}/invalid/.mnemorc" <<EOF
project: BadName
EOF
assert_eq "uppercase rejected" "" "$(walk_up_mnemorc "${TMP_ROOT}/invalid")"

# Test 10: .mnemorc missing project field → empty
mkdir -p "${TMP_ROOT}/noproj"
cat > "${TMP_ROOT}/noproj/.mnemorc" <<EOF
description: no project here
EOF
assert_eq "missing project field" "" "$(walk_up_mnemorc "${TMP_ROOT}/noproj")"

# Test 11: project starting with digit (invalid per Go regex)
mkdir -p "${TMP_ROOT}/badstart"
cat > "${TMP_ROOT}/badstart/.mnemorc" <<EOF
project: 1badstart
EOF
assert_eq "digit start rejected" "" "$(walk_up_mnemorc "${TMP_ROOT}/badstart")"

# Test 12: quoted project value
mkdir -p "${TMP_ROOT}/quoted"
cat > "${TMP_ROOT}/quoted/.mnemorc" <<EOF
project: "quoted-proj"
EOF
assert_eq "quoted value" "quoted-proj" "$(walk_up_mnemorc "${TMP_ROOT}/quoted")"

printf '\n=== detect_project ===\n'

# Test 13: .mnemorc wins over CWD basename
mkdir -p "${TMP_ROOT}/dp1"
cat > "${TMP_ROOT}/dp1/.mnemorc" <<EOF
project: explicit
EOF
assert_eq ".mnemorc overrides basename" "explicit" "$(detect_project "${TMP_ROOT}/dp1")"

# Test 14: no .mnemorc, no git → falls back to basename
mkdir -p "${TMP_ROOT}/plain_dir_name"
assert_eq "basename fallback" "plain_dir_name" "$(detect_project "${TMP_ROOT}/plain_dir_name")"

# Test 15: .mnemorc walk-up wins from nested subdir
mkdir -p "${TMP_ROOT}/root/sub/deeper"
cat > "${TMP_ROOT}/root/.mnemorc" <<EOF
project: rootproj
EOF
assert_eq "walk-up wins from nested" "rootproj" "$(detect_project "${TMP_ROOT}/root/sub/deeper")"

printf '\n=== cwd_hash ===\n'

# Deterministic hashes for non-existent paths (bash's `cd` fails, falls back
# to literal path). Must match the Go test in session_handoff_test.go.
assert_eq "cwd_hash /does/not/exist/alpha" "44de80dab77a0f2d" "$(cwd_hash /does/not/exist/alpha)"
assert_eq "cwd_hash /does/not/exist/beta"  "c220fe964f4e7e28" "$(cwd_hash /does/not/exist/beta)"
assert_eq "cwd_hash /does/not/exist/gamma" "e660be61fccd2323" "$(cwd_hash /does/not/exist/gamma)"

# Stable: same input → same output twice.
H1=$(cwd_hash /does/not/exist/stable)
H2=$(cwd_hash /does/not/exist/stable)
assert_eq "cwd_hash stable" "$H1" "$H2"

# Length 16 hex chars.
assert_eq "cwd_hash length 16" "16" "$(printf '%s' "$H1" | wc -c | tr -d ' ')"

printf '\n=== session handoff (write / read / clear) ===\n'

# Isolate handoff dir inside the sandbox so we never touch ~/.mnemo.
HANDOFF_SANDBOX="${TMP_ROOT}/handoff_data"
export MNEMO_DATA_DIR="$HANDOFF_SANDBOX"
# Re-compute the derived path so the helper picks up our override.
MNEMO_SESSION_HANDOFF_DIR="${MNEMO_DATA_DIR}/sessions/by-cwd"

mkdir -p "${TMP_ROOT}/chat_a" "${TMP_ROOT}/chat_b"

# Test IDs use the UUIDv4 format Claude Code gives every hook on stdin.
UUID_A="abc12345-6789-4def-9012-345678901234"
UUID_B="def98765-4321-4abc-b012-fedcba987654"

# Test: write then manual read yields the session ID for the matching CWD.
write_session_handoff "$UUID_A" "${TMP_ROOT}/chat_a"
HASH_A=$(cwd_hash "${TMP_ROOT}/chat_a")
GOT_A=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_A}.txt" 2>/dev/null | head -1)
assert_eq "write_session_handoff writes target file" "$UUID_A" "$GOT_A"

# Test: a different CWD does NOT see the other session's handoff.
HASH_B=$(cwd_hash "${TMP_ROOT}/chat_b")
GOT_B=""
if [ -f "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_B}.txt" ]; then
  GOT_B=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_B}.txt")
fi
assert_eq "handoff isolated per CWD" "" "$GOT_B"

# Test: a second chat can write its own UUID without clobbering the first.
write_session_handoff "$UUID_B" "${TMP_ROOT}/chat_b"
GOT_A_AFTER=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_A}.txt" 2>/dev/null | head -1)
GOT_B_AFTER=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_B}.txt" 2>/dev/null | head -1)
assert_eq "chat_a handoff preserved after chat_b write" "$UUID_A" "$GOT_A_AFTER"
assert_eq "chat_b handoff written with its own UUID"    "$UUID_B" "$GOT_B_AFTER"

# Test: rewrite the same CWD with a new UUID (simulates /clear rotating id).
NEW_UUID_A="11111111-2222-4333-8444-555555555555"
write_session_handoff "$NEW_UUID_A" "${TMP_ROOT}/chat_a"
GOT_A_ROTATED=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_A}.txt" 2>/dev/null | head -1)
assert_eq "rewrite on same CWD replaces previous id" "$NEW_UUID_A" "$GOT_A_ROTATED"

# Test: clear_session_handoff removes the file.
clear_session_handoff "${TMP_ROOT}/chat_a"
AFTER_CLEAR=""
if [ -f "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_A}.txt" ]; then
  AFTER_CLEAR="exists"
fi
assert_eq "clear_session_handoff removes file" "" "$AFTER_CLEAR"

# Test: write with empty session ID is a no-op (doesn't crash, doesn't write).
write_session_handoff "" "${TMP_ROOT}/chat_a"
POST_EMPTY=""
if [ -f "${MNEMO_SESSION_HANDOFF_DIR}/${HASH_A}.txt" ]; then
  POST_EMPTY="exists"
fi
assert_eq "empty session_id is no-op" "" "$POST_EMPTY"

# Test: atomic write (tmp file shouldn't leak after success).
write_session_handoff "22222222-3333-4444-8555-666666666666" "${TMP_ROOT}/chat_a"
LEAKED=$(find "${MNEMO_SESSION_HANDOFF_DIR}" -name '*.txt.*' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "no leftover tmp files after atomic write" "0" "$LEAKED"

# Test: write_session_handoff also writes latest.txt for hosts that launch
# the MCP subprocess from a different CWD (e.g. Claude Desktop with CWD=/).
rm -rf "$MNEMO_SESSION_HANDOFF_DIR"
LATEST_UUID="77777777-8888-4999-8aaa-bbbbbbbbbbbb"
write_session_handoff "$LATEST_UUID" "${TMP_ROOT}/chat_a"
GOT_LATEST=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/latest.txt" 2>/dev/null | head -1)
assert_eq "write_session_handoff writes latest.txt" "$LATEST_UUID" "$GOT_LATEST"

# Test: clear_session_handoff removes both the cwd-keyed file AND latest.txt.
clear_session_handoff "${TMP_ROOT}/chat_a"
LATEST_AFTER_CLEAR=""
if [ -f "${MNEMO_SESSION_HANDOFF_DIR}/latest.txt" ]; then
  LATEST_AFTER_CLEAR="exists"
fi
assert_eq "clear_session_handoff removes latest.txt" "" "$LATEST_AFTER_CLEAR"

# Test: a second chat overwrites latest.txt (last-writer-wins, which is
# exactly the semantics we want for short TTL fallback).
UUID_FIRST="aaaa1111-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
UUID_SECOND="bbbb2222-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
write_session_handoff "$UUID_FIRST"  "${TMP_ROOT}/chat_a"
write_session_handoff "$UUID_SECOND" "${TMP_ROOT}/chat_b"
GOT_LATEST_OVERWRITE=$(cat "${MNEMO_SESSION_HANDOFF_DIR}/latest.txt" 2>/dev/null | head -1)
assert_eq "latest.txt keeps most-recent writer" "$UUID_SECOND" "$GOT_LATEST_OVERWRITE"

printf '\n=== Summary ===\n'
printf 'Passed: %d\n' "$PASS"
printf 'Failed: %d\n' "$FAIL"

if [ $FAIL -gt 0 ]; then
  printf '\nFailed tests:\n'
  for t in "${FAILED_TESTS[@]}"; do
    printf '  - %s\n' "$t"
  done
  exit 1
fi

printf '\nAll tests passed ✓\n'
