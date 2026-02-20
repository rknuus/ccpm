#!/bin/bash
# test-stats.sh — Tests for scripts/pm/stats.sh
#
# Usage: bash tests/test-stats.sh
#
# Tests the helper functions (fmt_duration, fmt_number) and the overview/show
# commands against a synthetic active-context.json with real JSONL fixture data.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create a temporary working directory to isolate tests
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Set up the .pm structure inside test dir
mkdir -p "$TEST_DIR/.pm/stats"

# Create active-context.json with history entries matching session-1 and session-2 windows
cat > "$TEST_DIR/.pm/stats/active-context.json" <<'CTXEOF'
{
  "current": null,
  "history": [
    {
      "type": "prd",
      "name": "feature-auth",
      "command": "prd-new",
      "started": "2026-02-15T09:59:00Z",
      "ended": "2026-02-15T10:01:00Z"
    },
    {
      "type": "epic",
      "name": "feature-auth",
      "command": "epic-decompose",
      "started": "2026-02-15T10:59:00Z",
      "ended": "2026-02-15T11:01:00Z"
    }
  ]
}
CTXEOF

# Create ccpm-settings.json
echo '{ "collectPrompts": false }' > "$TEST_DIR/.pm/ccpm-settings.json"

# Override git rev-parse to return test dir (so stats_find_jsonl_files works
# with our fixtures). We'll pass files explicitly instead.
# We need to cd into test dir so the script reads .pm/ from there.
cd "$TEST_DIR"

# Override STATS_CONTEXT_FILE for ccpm-context script
STATS_CONTEXT_FILE="$TEST_DIR/.pm/stats/active-context.json"
export STATS_CONTEXT_FILE
source "$PROJECT_ROOT/scripts/pm/stats-lib.sh"

# Source stats.sh functions by extracting them (the main function exits, so we
# override main and source). We'll test via subshell calls to the script itself.

passed=0
failed=0

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $description"
    passed=$((passed + 1))
  else
    echo "  FAIL: $description"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    failed=$((failed + 1))
  fi
}

assert_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $description"
    passed=$((passed + 1))
  else
    echo "  FAIL: $description"
    echo "    expected to contain: $needle"
    echo "    actual output: $haystack"
    failed=$((failed + 1))
  fi
}

assert_not_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  FAIL: $description"
    echo "    expected NOT to contain: $needle"
    failed=$((failed + 1))
  else
    echo "  PASS: $description"
    passed=$((passed + 1))
  fi
}

# =========================================================================
echo ""
echo "=== fmt_duration tests ==="
# =========================================================================
# Source the stats.sh to get access to fmt_duration and fmt_number
# We source it with a modified main function to prevent execution
eval "$(sed 's/^main "$@"$//' "$PROJECT_ROOT/scripts/pm/stats.sh" | sed 's/^set -euo pipefail$//' | sed 's|^source.*stats-lib.sh.*$||' | sed 's|^SCRIPT_DIR=.*$||')"

assert_eq "0 seconds" "0s" "$(fmt_duration 0)"
assert_eq "30 seconds" "30s" "$(fmt_duration 30)"
assert_eq "59 seconds" "59s" "$(fmt_duration 59)"
assert_eq "60 seconds" "1m" "$(fmt_duration 60)"
assert_eq "90 seconds" "1m" "$(fmt_duration 90)"
assert_eq "3600 seconds" "1h" "$(fmt_duration 3600)"
assert_eq "3660 seconds" "1h 1m" "$(fmt_duration 3660)"
assert_eq "8100 seconds" "2h 15m" "$(fmt_duration 8100)"
assert_eq "float seconds" "15s" "$(fmt_duration 15.7)"

# =========================================================================
echo ""
echo "=== fmt_number tests ==="
# =========================================================================
assert_eq "zero" "0" "$(fmt_number 0)"
assert_eq "small number" "999" "$(fmt_number 999)"
assert_eq "thousands" "1,000" "$(fmt_number 1000)"
assert_eq "large number" "45,000" "$(fmt_number 45000)"
assert_eq "very large" "1,234,567" "$(fmt_number 1234567)"

# =========================================================================
echo ""
echo "=== fmt_rating tests ==="
# =========================================================================
assert_eq "no ratings" "-" "$(fmt_rating '{}')"
assert_eq "immediate only" "4/5" "$(fmt_rating '{"immediate":{"rating":4}}')"
assert_eq "delayed only" "3/5" "$(fmt_rating '{"delayed":{"rating":3}}')"
assert_eq "both prefers delayed" "3/5" "$(fmt_rating '{"immediate":{"rating":4},"delayed":{"rating":3}}')"

# =========================================================================
echo ""
echo "=== Overview: empty state ==="
# =========================================================================
# Create empty context file
cat > "$TEST_DIR/.pm/stats/active-context.json" <<'EOF'
{"current":null,"history":[]}
EOF

output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" overview 2>&1 || true)
assert_contains "empty state message" "No stats collected yet" "$output"

# =========================================================================
echo ""
echo "=== Overview: with data ==="
# =========================================================================
# Restore context with history
cat > "$TEST_DIR/.pm/stats/active-context.json" <<'CTXEOF'
{
  "current": null,
  "history": [
    {
      "type": "prd",
      "name": "feature-auth",
      "command": "prd-new",
      "started": "2026-02-15T09:59:00Z",
      "ended": "2026-02-15T10:01:00Z"
    },
    {
      "type": "epic",
      "name": "feature-auth",
      "command": "epic-decompose",
      "started": "2026-02-15T10:59:00Z",
      "ended": "2026-02-15T11:01:00Z"
    }
  ]
}
CTXEOF

output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" overview 2>&1 || true)
assert_contains "overview has header" "Type" "$output"
assert_contains "overview has prd row" "prd" "$output"
assert_contains "overview has epic row" "epic" "$output"
assert_contains "overview has TOTAL" "TOTAL" "$output"
assert_contains "overview has Sessions column" "Sessions" "$output"

# =========================================================================
echo ""
echo "=== Show: missing arguments ==="
# =========================================================================
output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show 2>&1 || true)
assert_contains "show usage" "Usage:" "$output"

# =========================================================================
echo ""
echo "=== Show: invalid type ==="
# =========================================================================
output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show "invalid" "name" 2>&1 || true)
assert_contains "invalid type error" "Invalid type" "$output"

# =========================================================================
echo ""
echo "=== Show: no stats for item ==="
# =========================================================================
output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show "task" "nonexistent" 2>&1 || true)
assert_contains "no stats message" "No stats found" "$output"

# =========================================================================
echo ""
echo "=== Show: with data ==="
# =========================================================================
output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show "prd" "feature-auth" 2>&1 || true)
assert_contains "show has summary" "Summary" "$output"
assert_contains "show has sessions" "Sessions" "$output"
assert_contains "show has model breakdown" "Model Breakdown" "$output"
assert_contains "show has time analysis" "Time Analysis" "$output"
assert_contains "show has prompts" "Prompts" "$output"
assert_contains "show has actions" "Actions" "$output"
assert_contains "show has stats-rate action" "/ccpm:stats-rate" "$output"

# =========================================================================
echo ""
echo "=== Show: prompts disabled message ==="
# =========================================================================
output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show "prd" "feature-auth" 2>&1 || true)
assert_contains "prompts disabled" "Prompt collection: disabled" "$output"
assert_contains "config hint" "/ccpm:config" "$output"

# =========================================================================
echo ""
echo "=== Cache: stats.json created ==="
# =========================================================================
assert_eq "prd cache exists" "true" \
  "$([ -f "$TEST_DIR/.pm/stats/prds/feature-auth/stats.json" ] && echo true || echo false)"
assert_eq "epic cache exists" "true" \
  "$([ -f "$TEST_DIR/.pm/stats/epics/feature-auth/stats.json" ] && echo true || echo false)"

# Check cache has computed_at
computed_at=$(jq -r '.computed_at // empty' "$TEST_DIR/.pm/stats/prds/feature-auth/stats.json" 2>/dev/null)
assert_eq "cache has computed_at" "true" "$([ -n "$computed_at" ] && echo true || echo false)"

# Check cache has satisfaction field preserved
sat=$(jq '.satisfaction' "$TEST_DIR/.pm/stats/prds/feature-auth/stats.json" 2>/dev/null)
assert_eq "cache has satisfaction field" "true" "$([ "$sat" != "null" ] && echo true || echo false)"

# =========================================================================
echo ""
echo "=== Cache: satisfaction preserved after recompute ==="
# =========================================================================
# Add a satisfaction rating to the cache
source "$PROJECT_ROOT/scripts/pm/stats-satisfaction.sh"
stats_save_rating "prd" "feature-auth" "immediate" "4" > /dev/null 2>&1

# Force recompute by adding a newer history entry
cat > "$TEST_DIR/.pm/stats/active-context.json" <<'CTXEOF'
{
  "current": null,
  "history": [
    {
      "type": "prd",
      "name": "feature-auth",
      "command": "prd-new",
      "started": "2026-02-15T09:59:00Z",
      "ended": "2026-02-15T10:01:00Z"
    },
    {
      "type": "prd",
      "name": "feature-auth",
      "command": "prd-edit",
      "started": "2026-02-15T23:59:00Z",
      "ended": "2026-02-15T23:59:59Z"
    },
    {
      "type": "epic",
      "name": "feature-auth",
      "command": "epic-decompose",
      "started": "2026-02-15T10:59:00Z",
      "ended": "2026-02-15T11:01:00Z"
    }
  ]
}
CTXEOF

output=$(bash "$PROJECT_ROOT/scripts/pm/stats.sh" show "prd" "feature-auth" 2>&1 || true)
sat_rating=$(jq -r '.satisfaction.immediate.rating // empty' "$TEST_DIR/.pm/stats/prds/feature-auth/stats.json" 2>/dev/null)
assert_eq "satisfaction preserved after recompute" "4" "$sat_rating"

# Check the show output reflects the rating
assert_contains "show includes rating" "4/5" "$output"

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
