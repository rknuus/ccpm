#!/bin/bash
# test-stats-lib.sh — Tests for scripts/pm/stats-lib.sh
#
# Usage: bash tests/test-stats-lib.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the library under test
# shellcheck source=../scripts/pm/stats-lib.sh
source "$PROJECT_ROOT/scripts/pm/stats-lib.sh"

FIXTURES="$SCRIPT_DIR/fixtures"
SESSION_1="$FIXTURES/session-1.jsonl"
SESSION_2="$FIXTURES/session-2.jsonl"
SESSION_OUTSIDE="$FIXTURES/session-outside.jsonl"

# Time window that covers session-1 and session-2 but not session-outside
START="2026-02-15T00:00:00.000Z"
END="2026-02-15T23:59:59.999Z"

passed=0
failed=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $label"
    passed=$((passed + 1))
  else
    echo "  FAIL: $label"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    failed=$((failed + 1))
  fi
}

# =========================================================================
echo ""
echo "=== Token Summation: single session ==="
# =========================================================================
# session-1 has 3 assistant entries (all claude-opus-4-6):
#   input: 100+150+80=330, output: 200+300+50=550,
#   cache_creation: 50+60+0=110, cache_read: 30+40+100=170
result=$(stats_sum_tokens "$START" "$END" "$SESSION_1")

assert_eq "total input" "330" "$(echo "$result" | jq '.total.input')"
assert_eq "total output" "550" "$(echo "$result" | jq '.total.output')"
assert_eq "total cache_creation" "110" "$(echo "$result" | jq '.total.cache_creation')"
assert_eq "total cache_read" "170" "$(echo "$result" | jq '.total.cache_read')"
assert_eq "by_model opus input" "330" "$(echo "$result" | jq '.by_model["claude-opus-4-6"].input')"

# =========================================================================
echo ""
echo "=== Token Summation: multi-session, multiple models ==="
# =========================================================================
# session-2 has:
#   claude-sonnet-4-20250514: input=200, output=400, cache_creation=100, cache_read=0
#   claude-opus-4-6: input=120, output=250, cache_creation=30, cache_read=20
# Combined with session-1 opus totals: input=330+120=450, output=550+250=800,
#   cache_creation=110+30=140, cache_read=170+20=190
result=$(stats_sum_tokens "$START" "$END" "$SESSION_1" "$SESSION_2")

assert_eq "multi total input" "650" "$(echo "$result" | jq '.total.input')"
assert_eq "multi total output" "1200" "$(echo "$result" | jq '.total.output')"
assert_eq "multi total cache_creation" "240" "$(echo "$result" | jq '.total.cache_creation')"
assert_eq "multi total cache_read" "190" "$(echo "$result" | jq '.total.cache_read')"
assert_eq "multi opus input" "450" "$(echo "$result" | jq '.by_model["claude-opus-4-6"].input')"
assert_eq "multi sonnet input" "200" "$(echo "$result" | jq '.by_model["claude-sonnet-4-20250514"].input')"
assert_eq "multi sonnet output" "400" "$(echo "$result" | jq '.by_model["claude-sonnet-4-20250514"].output')"

# =========================================================================
echo ""
echo "=== Token Summation: excludes entries outside window ==="
# =========================================================================
# session-outside is from 2026-02-14, outside our START..END window
result=$(stats_sum_tokens "$START" "$END" "$SESSION_1" "$SESSION_OUTSIDE")

assert_eq "excludes outside input" "330" "$(echo "$result" | jq '.total.input')"
assert_eq "excludes outside output" "550" "$(echo "$result" | jq '.total.output')"

# =========================================================================
echo ""
echo "=== Token Summation: empty JSONL file ==="
# =========================================================================
SESSION_EMPTY="$FIXTURES/session-empty.jsonl"
result=$(stats_sum_tokens "$START" "$END" "$SESSION_EMPTY")
assert_eq "empty total input" "0" "$(echo "$result" | jq '.total.input')"

# =========================================================================
echo ""
echo "=== Time Derivation: single session ==="
# =========================================================================
# session-1 message sequence (within window):
#   user  10:00:00 -> assistant 10:00:05 => claude working 5s
#   assistant 10:00:05 -> user 10:00:15 => user wait 10s
#   user  10:00:15 -> assistant 10:00:22 => claude working 7s
#   assistant 10:00:22 -> user(tool) 10:00:22.5 => user wait 0.5s
#   user(tool) 10:00:22.5 -> assistant 10:00:25 => claude working 2.5s
#   assistant 10:00:25 -> user 10:00:35 => user wait 10s
#
# Note: jq fromdateiso8601 truncates to seconds:
#   tool result at 10:00:22.500 truncates to 10:00:22
#   So: assistant 10:00:22 -> user 10:00:22 = 0s wait
#       user 10:00:22 -> assistant 10:00:25 = 3s working
#       assistant 10:00:25 -> user 10:00:35 = 10s wait
#
# Total claude working: 5 + 7 + 3 = 15s
# Total user wait: 10 + 0 + 10 = 20s
result=$(stats_derive_time "$START" "$END" "$SESSION_1")

assert_eq "claude working seconds" "15" "$(echo "$result" | jq '.claude_working_seconds')"
assert_eq "user wait seconds" "20" "$(echo "$result" | jq '.user_wait_seconds')"

# =========================================================================
echo ""
echo "=== Time Derivation: multi-session ==="
# =========================================================================
# session-2:
#   user  11:00:00 -> assistant 11:00:08 => claude working 8s
#   assistant 11:00:08 -> user 11:00:20 => user wait 12s
#   user  11:00:20 -> assistant 11:00:28 => claude working 8s
#
# Combined with session-1 (15 + 8 + 8 = 31 working, 20 + 12 = 32 wait)
# Note: gap between session-1 last user (10:00:35) and session-2 first user
# (11:00:00) is NOT counted because it goes user->user (no pair).
result=$(stats_derive_time "$START" "$END" "$SESSION_1" "$SESSION_2")

assert_eq "multi claude working" "31" "$(echo "$result" | jq '.claude_working_seconds')"
assert_eq "multi user wait" "32" "$(echo "$result" | jq '.user_wait_seconds')"

# =========================================================================
echo ""
echo "=== Time Derivation: excludes entries outside window ==="
# =========================================================================
result=$(stats_derive_time "$START" "$END" "$SESSION_1" "$SESSION_OUTSIDE")
assert_eq "excludes outside claude working" "15" "$(echo "$result" | jq '.claude_working_seconds')"

# =========================================================================
echo ""
echo "=== Time Derivation: empty JSONL file ==="
# =========================================================================
result=$(stats_derive_time "$START" "$END" "$SESSION_EMPTY")
assert_eq "empty claude working" "0" "$(echo "$result" | jq '.claude_working_seconds')"

# =========================================================================
echo ""
echo "=== Idle Detection: excludes gaps exceeding threshold ==="
# =========================================================================
# session-idle has:
#   user  14:00:00 -> assistant 14:00:05 => 5s working
#   assistant 14:00:05 -> user 14:00:15 => 10s wait
#   user  14:00:15 -> assistant 14:00:20 => 5s working
#   assistant 14:00:20 -> user 22:00:20 => 8h gap (IDLE - should be excluded)
#   user  22:00:20 -> assistant 22:00:28 => 8s working
#
# With idle detection (threshold=300s): working=5+5+8=18s, wait=10s
# Without idle detection: working=5+5+8=18s, wait=10+28800=28810s
SESSION_IDLE="$FIXTURES/session-idle.jsonl"
STATS_IDLE_THRESHOLD_SECS=300 result=$(stats_derive_time "$START" "$END" "$SESSION_IDLE")

assert_eq "idle: claude working" "18" "$(echo "$result" | jq '.claude_working_seconds')"
assert_eq "idle: user wait (excludes 8h gap)" "10" "$(echo "$result" | jq '.user_wait_seconds')"

# =========================================================================
echo ""
echo "=== Idle Detection: includes gaps below threshold ==="
# =========================================================================
# With a very high threshold (999999s), all gaps should be included
STATS_IDLE_THRESHOLD_SECS=999999 result=$(stats_derive_time "$START" "$END" "$SESSION_IDLE")

assert_eq "no-idle: claude working" "18" "$(echo "$result" | jq '.claude_working_seconds')"
assert_eq "no-idle: user wait (includes 8h gap)" "28810" "$(echo "$result" | jq '.user_wait_seconds')"

# =========================================================================
echo ""
echo "=== Idle Detection: existing session-1 unaffected ==="
# =========================================================================
# session-1 has no gaps > 300s, so idle detection should not change results
STATS_IDLE_THRESHOLD_SECS=300 result=$(stats_derive_time "$START" "$END" "$SESSION_1")

assert_eq "idle s1: claude working unchanged" "15" "$(echo "$result" | jq '.claude_working_seconds')"
assert_eq "idle s1: user wait unchanged" "20" "$(echo "$result" | jq '.user_wait_seconds')"

# =========================================================================
echo ""
echo "=== Prompt Extraction: single session ==="
# =========================================================================
# session-1 has 3 user messages with string content (tool result excluded):
#   "Implement the login feature"
#   "Add error handling too"
#   "Looks good, thanks!"
prompts=$(stats_extract_prompts "$START" "$END" "$SESSION_1")
prompt_count=$(echo "$prompts" | grep -c '.')

assert_eq "prompt count" "3" "$prompt_count"

# Check first prompt content (after tab)
first_prompt=$(echo "$prompts" | head -1 | cut -f2)
assert_eq "first prompt" "Implement the login feature" "$first_prompt"

# Check that tool result is excluded (should not contain "file written")
if echo "$prompts" | grep -q "file written"; then
  echo "  FAIL: tool result should be excluded from prompts"
  failed=$((failed + 1))
else
  echo "  PASS: tool result excluded"
  passed=$((passed + 1))
fi

# =========================================================================
echo ""
echo "=== Prompt Extraction: multi-session ==="
# =========================================================================
prompts=$(stats_extract_prompts "$START" "$END" "$SESSION_1" "$SESSION_2")
prompt_count=$(echo "$prompts" | grep -c '.')

assert_eq "multi prompt count" "5" "$prompt_count"

# =========================================================================
echo ""
echo "=== Prompt Extraction: excludes entries outside window ==="
# =========================================================================
prompts=$(stats_extract_prompts "$START" "$END" "$SESSION_1" "$SESSION_OUTSIDE")
prompt_count=$(echo "$prompts" | grep -c '.')

assert_eq "excludes outside prompts" "3" "$prompt_count"

# =========================================================================
echo ""
echo "=== Prompt Extraction: timestamp prefix format ==="
# =========================================================================
prompts=$(stats_extract_prompts "$START" "$END" "$SESSION_1")
first_line=$(echo "$prompts" | head -1)
first_ts=$(echo "$first_line" | cut -f1)

assert_eq "timestamp prefix" "2026-02-15T10:00:00.000Z" "$first_ts"

# =========================================================================
echo ""
echo "=== File Discovery: excludes subagent JSONL files ==="
# =========================================================================
# Create a temp directory mimicking the Claude projects structure
MOCK_CLAUDE_DIR="$(mktemp -d)"
trap 'rm -rf "$MOCK_CLAUDE_DIR" "$OLD_FILE" "$COMPRESS_TEST_DIR"' EXIT

# Simulate project dir name (the function uses git rev-parse)
PROJECT_DIR_NAME="$(git rev-parse --show-toplevel 2>/dev/null | sed 's|/|-|g')"
MOCK_PROJECT_DIR="$MOCK_CLAUDE_DIR/$PROJECT_DIR_NAME"
mkdir -p "$MOCK_PROJECT_DIR"

# Create a top-level JSONL file
echo '{}' > "$MOCK_PROJECT_DIR/session-main.jsonl"

# Create a subagent JSONL file
mkdir -p "$MOCK_PROJECT_DIR/abc123/subagents"
echo '{}' > "$MOCK_PROJECT_DIR/abc123/subagents/agent-1.jsonl"

# Override HOME so stats_find_jsonl_files looks in our mock dir
OLD_HOME="$HOME"
HOME="$MOCK_CLAUDE_DIR"
# Rename project dir to match expected path under .claude/projects/
mkdir -p "$MOCK_CLAUDE_DIR/.claude/projects"
mv "$MOCK_PROJECT_DIR" "$MOCK_CLAUDE_DIR/.claude/projects/$PROJECT_DIR_NAME"

found_files=$(stats_find_jsonl_files)
HOME="$OLD_HOME"

if echo "$found_files" | grep -qF "session-main.jsonl"; then
  echo "  PASS: discovery includes top-level JSONL"
  passed=$((passed + 1))
else
  echo "  FAIL: discovery should include top-level JSONL"
  echo "    found: $found_files"
  failed=$((failed + 1))
fi

if echo "$found_files" | grep -qF "subagents"; then
  echo "  FAIL: discovery should exclude subagent JSONL files"
  echo "    found: $found_files"
  failed=$((failed + 1))
else
  echo "  PASS: discovery excludes subagent JSONL"
  passed=$((passed + 1))
fi

# =========================================================================
echo ""
echo "=== File Filtering: includes files with recent mtime ==="
# =========================================================================
# Touch session-1 to set its mtime to "now" (within any window)
# and session-outside to a date before our START window
touch -t 202602150500.00 "$SESSION_OUTSIDE" 2>/dev/null || true
touch "$SESSION_1" 2>/dev/null || true

# Filter with START that is before session-1's mtime
filtered=$(stats_filter_files_by_timerange "$START" "$END" "$SESSION_1" "$SESSION_OUTSIDE")
filtered_count=$(echo "$filtered" | grep -c '.' 2>/dev/null || echo "0")

# session-1 was just touched (mtime=now, >> START), should be included
if echo "$filtered" | grep -qF "session-1.jsonl"; then
  echo "  PASS: filter includes recent file"
  passed=$((passed + 1))
else
  echo "  FAIL: filter should include recent file"
  echo "    filtered: $filtered"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== File Filtering: excludes files with old mtime ==="
# =========================================================================
# Create a temp file with a very old mtime
OLD_FILE="$(mktemp)"
trap 'rm -rf "$OLD_FILE" "$MOCK_CLAUDE_DIR"' EXIT
echo '{}' > "$OLD_FILE"
touch -t 202001010000.00 "$OLD_FILE" 2>/dev/null || true

filtered=$(stats_filter_files_by_timerange "$START" "$END" "$OLD_FILE")
if [ -z "$filtered" ]; then
  echo "  PASS: filter excludes old file"
  passed=$((passed + 1))
else
  echo "  FAIL: filter should exclude old file"
  echo "    filtered: $filtered"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== File Filtering: returns empty for no matching files ==="
# =========================================================================
filtered=$(stats_filter_files_by_timerange "$START" "$END" "$OLD_FILE")
filtered_count=$(echo "$filtered" | grep -c '.' 2>/dev/null || echo "0")
if [ -z "$filtered" ]; then
  echo "  PASS: filter returns empty for no matches"
  passed=$((passed + 1))
else
  echo "  FAIL: filter should return empty for no matches"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== File Filtering: passes through explicit files unchanged ==="
# =========================================================================
# When explicit files are passed to stats_sum_tokens, filtering is NOT applied
# (the files are used as-is). Verify existing behavior is preserved.
result=$(stats_sum_tokens "$START" "$END" "$SESSION_1")
assert_eq "explicit files still work" "330" "$(echo "$result" | jq '.total.input')"

# =========================================================================
echo ""
echo "=== stats_cat_files: plain and compressed ==="
# =========================================================================
CAT_TEST_DIR="$(mktemp -d)"

# Create a plain test JSONL file with known content
cat > "$CAT_TEST_DIR/test-plain.jsonl" <<'CATEOF'
{"type":"assistant","timestamp":"2026-01-01T00:00:00Z","message":{"usage":{"input_tokens":100,"output_tokens":50}}}
{"type":"assistant","timestamp":"2026-01-01T00:01:00Z","message":{"usage":{"input_tokens":200,"output_tokens":75}}}
CATEOF

# Test reading plain file
plain_out=$(stats_cat_files "$CAT_TEST_DIR/test-plain.jsonl")
plain_lines=$(echo "$plain_out" | wc -l | tr -d ' ')
assert_eq "cat_files plain line count" "2" "$plain_lines"

# Create a gzipped copy
cp "$CAT_TEST_DIR/test-plain.jsonl" "$CAT_TEST_DIR/test-gz.jsonl"
gzip "$CAT_TEST_DIR/test-gz.jsonl"

# Test reading gzipped file produces identical content
gz_out=$(stats_cat_files "$CAT_TEST_DIR/test-gz.jsonl.gz")
assert_eq "cat_files gz output matches plain" "$plain_out" "$gz_out"

# Test reading both plain and gz together
both_out=$(stats_cat_files "$CAT_TEST_DIR/test-plain.jsonl" "$CAT_TEST_DIR/test-gz.jsonl.gz")
both_lines=$(echo "$both_out" | wc -l | tr -d ' ')
assert_eq "cat_files both files line count" "4" "$both_lines"

rm -rf "$CAT_TEST_DIR"

# =========================================================================
echo ""
echo "=== stats_compress_old_files: compression and idempotency ==="
# =========================================================================
COMPRESS_TEST_DIR="$(mktemp -d)"
FAKE_PROJECT="/tmp/test-compress-project-$$"
COMPRESS_DIR_NAME="${FAKE_PROJECT//\//-}"
mkdir -p "$COMPRESS_TEST_DIR/.claude/projects/$COMPRESS_DIR_NAME"

COMPRESS_PROJECT_DIR="$COMPRESS_TEST_DIR/.claude/projects/$COMPRESS_DIR_NAME"

# Create 3 JSONL files with old mtimes (30 days ago)
echo '{"type":"assistant","timestamp":"2026-01-01T00:00:00Z"}' > "$COMPRESS_PROJECT_DIR/old-session-1.jsonl"
echo '{"type":"assistant","timestamp":"2026-01-02T00:00:00Z"}' > "$COMPRESS_PROJECT_DIR/old-session-2.jsonl"
echo '{"type":"assistant","timestamp":"2026-01-03T00:00:00Z"}' > "$COMPRESS_PROJECT_DIR/new-session.jsonl"

# Set old mtimes (30 days ago) for old files
touch -t 202601010000.00 "$COMPRESS_PROJECT_DIR/old-session-1.jsonl"
touch -t 202601020000.00 "$COMPRESS_PROJECT_DIR/old-session-2.jsonl"

# new-session has current mtime (just created) — it will be the newest

# Override git rev-parse so stats_compress_old_files finds our fake project
_real_git=$(command -v git)
git() {
  if [[ "$1" == "rev-parse" && "$2" == "--show-toplevel" ]]; then
    echo "$FAKE_PROJECT"
  else
    "$_real_git" "$@"
  fi
}
export -f git

OLD_HOME_COMPRESS="$HOME"
HOME="$COMPRESS_TEST_DIR" stats_compress_old_files 0

# Restore
HOME="$OLD_HOME_COMPRESS"
unset -f git

# Check: old files should be compressed
if [ -f "$COMPRESS_PROJECT_DIR/old-session-1.jsonl.gz" ]; then
  echo "  PASS: old-session-1 compressed"
  passed=$((passed + 1))
else
  echo "  FAIL: old-session-1 should be compressed"
  failed=$((failed + 1))
fi

if [ -f "$COMPRESS_PROJECT_DIR/old-session-2.jsonl.gz" ]; then
  echo "  PASS: old-session-2 compressed"
  passed=$((passed + 1))
else
  echo "  FAIL: old-session-2 should be compressed"
  failed=$((failed + 1))
fi

# Check: newest file should remain uncompressed
if [ -f "$COMPRESS_PROJECT_DIR/new-session.jsonl" ]; then
  echo "  PASS: newest file remains uncompressed"
  passed=$((passed + 1))
else
  echo "  FAIL: newest file should remain uncompressed"
  failed=$((failed + 1))
fi

# Test idempotency: running again should not change anything
_real_git2=$(command -v git)
git() {
  if [[ "$1" == "rev-parse" && "$2" == "--show-toplevel" ]]; then
    echo "$FAKE_PROJECT"
  else
    "$_real_git2" "$@"
  fi
}
export -f git

before_count=$(find "$COMPRESS_PROJECT_DIR" -type f | wc -l | tr -d ' ')
HOME="$COMPRESS_TEST_DIR" stats_compress_old_files 0
after_count=$(find "$COMPRESS_PROJECT_DIR" -type f | wc -l | tr -d ' ')

HOME="$OLD_HOME_COMPRESS"
unset -f git

assert_eq "idempotent: file count unchanged" "$before_count" "$after_count"

rm -rf "$COMPRESS_TEST_DIR"

# =========================================================================
echo ""
echo "=== Token/time correctness with compressed files ==="
# =========================================================================
GZ_FIXTURE_DIR="$(mktemp -d)"

# Copy session-1 fixture as plain file
cp "$SESSION_1" "$GZ_FIXTURE_DIR/session-plain.jsonl"

# Compute tokens from plain file
plain_tokens=$(stats_sum_tokens "$START" "$END" "$GZ_FIXTURE_DIR/session-plain.jsonl")
plain_input=$(echo "$plain_tokens" | jq '.total.input')

# Create gzipped version
cp "$GZ_FIXTURE_DIR/session-plain.jsonl" "$GZ_FIXTURE_DIR/session-gz.jsonl"
gzip "$GZ_FIXTURE_DIR/session-gz.jsonl"

# Compute tokens from gzipped file
gz_tokens=$(stats_sum_tokens "$START" "$END" "$GZ_FIXTURE_DIR/session-gz.jsonl.gz")
gz_input=$(echo "$gz_tokens" | jq '.total.input')

assert_eq "tokens from gz match plain" "$plain_input" "$gz_input"

# Full token comparison
plain_output=$(echo "$plain_tokens" | jq '.total.output')
gz_output=$(echo "$gz_tokens" | jq '.total.output')
assert_eq "output tokens from gz match plain" "$plain_output" "$gz_output"

# Test time derivation with compressed files
plain_time=$(stats_derive_time "$START" "$END" "$GZ_FIXTURE_DIR/session-plain.jsonl")
gz_time=$(stats_derive_time "$START" "$END" "$GZ_FIXTURE_DIR/session-gz.jsonl.gz")

plain_working=$(echo "$plain_time" | jq '.claude_working_seconds')
gz_working=$(echo "$gz_time" | jq '.claude_working_seconds')
assert_eq "working seconds from gz match plain" "$plain_working" "$gz_working"

plain_waiting=$(echo "$plain_time" | jq '.user_wait_seconds')
gz_waiting=$(echo "$gz_time" | jq '.user_wait_seconds')
assert_eq "waiting seconds from gz match plain" "$plain_waiting" "$gz_waiting"

rm -rf "$GZ_FIXTURE_DIR"

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
