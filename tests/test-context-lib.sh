#!/bin/bash
# Tests for scripts/pm/context-lib.sh
# Run from project root: bash tests/test-context-lib.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Use a temporary directory so we don't touch real project data
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Override the context file path before sourcing
STATS_CONTEXT_FILE="$TEST_DIR/.pm/stats/active-context.json"
source "$PROJECT_ROOT/scripts/pm/context-lib.sh"

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

# ─── Test 1: File creation on first use ───

echo "Test 1: File creation on first use"
_stats_context_ensure_file
assert_eq "context file exists" "true" "$([ -f "$STATS_CONTEXT_FILE" ] && echo true || echo false)"
assert_eq "current is null" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history is empty array" "0" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 2: Open a context ───

echo ""
echo "Test 2: Open a context"
stats_context_open "prd" "feature-auth" "prd-new"
assert_eq "current type is prd" "prd" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "current name is feature-auth" "feature-auth" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "current command is prd-new" "prd-new" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
assert_eq "current has started timestamp" "true" "$(jq -r '.current.started != null' "$STATS_CONTEXT_FILE")"
assert_eq "history still empty" "0" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 3: Close a context ───

echo ""
echo "Test 3: Close a context"
# Small delay so ended != started
sleep 1
stats_context_close
assert_eq "current is null after close" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history has 1 entry" "1" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"
assert_eq "history entry has ended" "true" "$(jq -r '.history[0].ended != null' "$STATS_CONTEXT_FILE")"
assert_eq "history entry type" "prd" "$(jq -r '.history[0].type' "$STATS_CONTEXT_FILE")"
assert_eq "history entry name" "feature-auth" "$(jq -r '.history[0].name' "$STATS_CONTEXT_FILE")"
assert_eq "history entry command" "prd-new" "$(jq -r '.history[0].command' "$STATS_CONTEXT_FILE")"

# ─── Test 4: Close when no active context (no-op) ───

echo ""
echo "Test 4: Close when no active context (no-op)"
stats_context_close
assert_eq "current still null" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history still has 1 entry" "1" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 5: Switch context (open while already open) ───

echo ""
echo "Test 5: Switch context (open while already open)"
stats_context_open "epic" "auth-epic" "epic-decompose"
assert_eq "current type is epic" "epic" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
sleep 1
stats_context_open "task" "implement-login" "issue-start"
assert_eq "current type switched to task" "task" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "current name switched" "implement-login" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "current command switched" "issue-start" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
assert_eq "history has 2 entries (1 original + auto-closed epic)" "2" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"
assert_eq "auto-closed entry type is epic" "epic" "$(jq -r '.history[1].type' "$STATS_CONTEXT_FILE")"
assert_eq "auto-closed entry has ended" "true" "$(jq -r '.history[1].ended != null' "$STATS_CONTEXT_FILE")"

# ─── Test 6: History query ───

echo ""
echo "Test 6: History query"
stats_context_close
# Now history should have: prd/feature-auth, epic/auth-epic, task/implement-login

prd_history="$(stats_context_history "prd" "feature-auth")"
assert_eq "prd history has 1 entry" "1" "$(echo "$prd_history" | jq 'length')"
assert_eq "prd history entry name" "feature-auth" "$(echo "$prd_history" | jq -r '.[0].name')"

epic_history="$(stats_context_history "epic" "auth-epic")"
assert_eq "epic history has 1 entry" "1" "$(echo "$epic_history" | jq 'length')"

task_history="$(stats_context_history "task" "implement-login")"
assert_eq "task history has 1 entry" "1" "$(echo "$task_history" | jq 'length')"

no_history="$(stats_context_history "prd" "nonexistent")"
assert_eq "nonexistent item returns empty array" "0" "$(echo "$no_history" | jq 'length')"

# ─── Test 7: Missing arguments are safe ───

echo ""
echo "Test 7: Missing arguments are safe"
stats_context_open "" "" ""
assert_eq "current still null after empty open" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"

empty_history="$(stats_context_history "" "")"
assert_eq "empty args returns empty array" "0" "$(echo "$empty_history" | jq 'length')"

# ─── Summary ───

echo ""
echo "=============================="
echo "Results: $passed passed, $failed failed"
if [ "$failed" -gt 0 ]; then
  exit 1
else
  echo "All tests passed."
  exit 0
fi
