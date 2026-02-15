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
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
