#!/bin/bash
# Tests for scripts/pm/ccpm-context
# Run from project root: bash tests/test-context-lib.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Use a temporary directory so we don't touch real project data
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Override the context file path via environment variable
export STATS_CONTEXT_FILE="$TEST_DIR/.pm/stats/active-context.json"

CCPM_CONTEXT="$PROJECT_ROOT/scripts/pm/ccpm-context"

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
"$CCPM_CONTEXT" close
assert_eq "context file exists" "true" "$([ -f "$STATS_CONTEXT_FILE" ] && echo true || echo false)"
assert_eq "current is null" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history is empty array" "0" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 2: Open a context ───

echo ""
echo "Test 2: Open a context"
"$CCPM_CONTEXT" open "initiative" "feature-auth" "initiative-new"
assert_eq "current type is initiative" "initiative" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "current name is feature-auth" "feature-auth" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "current command is initiative-new" "initiative-new" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
assert_eq "current has started timestamp" "true" "$(jq -r '.current.started != null' "$STATS_CONTEXT_FILE")"
assert_eq "history still empty" "0" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 3: Close a context ───

echo ""
echo "Test 3: Close a context"
# Small delay so ended != started
sleep 1
"$CCPM_CONTEXT" close
assert_eq "current is null after close" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history has 1 entry" "1" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"
assert_eq "history entry has ended" "true" "$(jq -r '.history[0].ended != null' "$STATS_CONTEXT_FILE")"
assert_eq "history entry type" "initiative" "$(jq -r '.history[0].type' "$STATS_CONTEXT_FILE")"
assert_eq "history entry name" "feature-auth" "$(jq -r '.history[0].name' "$STATS_CONTEXT_FILE")"
assert_eq "history entry command" "initiative-new" "$(jq -r '.history[0].command' "$STATS_CONTEXT_FILE")"

# ─── Test 4: Close when no active context (no-op) ───

echo ""
echo "Test 4: Close when no active context (no-op)"
"$CCPM_CONTEXT" close
assert_eq "current still null" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
assert_eq "history still has 1 entry" "1" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"

# ─── Test 5: Switch context (open while already open) ───

echo ""
echo "Test 5: Switch context (open while already open)"
"$CCPM_CONTEXT" open "epic" "auth-epic" "epic-decompose"
assert_eq "current type is epic" "epic" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
sleep 1
"$CCPM_CONTEXT" open "task" "implement-login" "issue-start"
assert_eq "current type switched to task" "task" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "current name switched" "implement-login" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "current command switched" "issue-start" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
assert_eq "history has 2 entries (1 original + auto-closed epic)" "2" "$(jq '.history | length' "$STATS_CONTEXT_FILE")"
assert_eq "auto-closed entry type is epic" "epic" "$(jq -r '.history[1].type' "$STATS_CONTEXT_FILE")"
assert_eq "auto-closed entry has ended" "true" "$(jq -r '.history[1].ended != null' "$STATS_CONTEXT_FILE")"

# ─── Test 6: History query ───

echo ""
echo "Test 6: History query"
"$CCPM_CONTEXT" close
# Now history should have: initiative/feature-auth, epic/auth-epic, task/implement-login

initiative_history="$("$CCPM_CONTEXT" history "initiative" "feature-auth")"
assert_eq "initiative history has 1 entry" "1" "$(echo "$initiative_history" | jq 'length')"
assert_eq "initiative history entry name" "feature-auth" "$(echo "$initiative_history" | jq -r '.[0].name')"

epic_history="$("$CCPM_CONTEXT" history "epic" "auth-epic")"
assert_eq "epic history has 1 entry" "1" "$(echo "$epic_history" | jq 'length')"

task_history="$("$CCPM_CONTEXT" history "task" "implement-login")"
assert_eq "task history has 1 entry" "1" "$(echo "$task_history" | jq 'length')"

no_history="$("$CCPM_CONTEXT" history "initiative" "nonexistent")"
assert_eq "nonexistent item returns empty array" "0" "$(echo "$no_history" | jq 'length')"

# ─── Test 7: Missing arguments are safe ───

echo ""
echo "Test 7: Missing arguments are safe"
"$CCPM_CONTEXT" open "" "" ""
assert_eq "current still null after empty open" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"

empty_history="$("$CCPM_CONTEXT" history "" "")"
assert_eq "empty args returns empty array" "0" "$(echo "$empty_history" | jq 'length')"

# ─── Test 8: Reopen reopens last context within time window ───

echo ""
echo "Test 8: Reopen reopens last context within time window"
# History already has entries from previous tests; current is null after Test 6 close.
# Add a fresh entry and close it so its ended timestamp is recent.
"$CCPM_CONTEXT" open "epic" "recent-epic" "epic-start"
sleep 1
"$CCPM_CONTEXT" close
assert_eq "current null before reopen" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"
"$CCPM_CONTEXT" reopen 30
assert_eq "reopened type" "epic" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "reopened name" "recent-epic" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "reopened command is followup" "followup" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
# Clean up for next test
"$CCPM_CONTEXT" close

# ─── Test 9: Reopen does nothing when context is already open ───

echo ""
echo "Test 9: Reopen does nothing when context is already open"
"$CCPM_CONTEXT" open "initiative" "active-initiative" "initiative-new"
"$CCPM_CONTEXT" reopen 30
assert_eq "still original type" "initiative" "$(jq -r '.current.type' "$STATS_CONTEXT_FILE")"
assert_eq "still original name" "active-initiative" "$(jq -r '.current.name' "$STATS_CONTEXT_FILE")"
assert_eq "still original command" "initiative-new" "$(jq -r '.current.command' "$STATS_CONTEXT_FILE")"
"$CCPM_CONTEXT" close

# ─── Test 10: Reopen does nothing when last context is stale ───

echo ""
echo "Test 10: Reopen does nothing when last context is stale"
# Manually inject a history entry with an ended timestamp 2 hours ago
two_hours_ago="$(date -u -v-2H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ")"
jq --arg ended "$two_hours_ago" \
  '.history += [{"type":"epic","name":"stale-epic","command":"epic-start","started":"2026-01-01T00:00:00Z","ended":$ended}] | .current = null' \
  "$STATS_CONTEXT_FILE" > "${STATS_CONTEXT_FILE}.tmp" && mv "${STATS_CONTEXT_FILE}.tmp" "$STATS_CONTEXT_FILE"
"$CCPM_CONTEXT" reopen 30
assert_eq "no reopen for stale context" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"

# ─── Test 11: Reopen does nothing when history is empty ───

echo ""
echo "Test 11: Reopen does nothing when history is empty"
printf '{"current":null,"history":[]}\n' > "$STATS_CONTEXT_FILE"
"$CCPM_CONTEXT" reopen 30
assert_eq "no reopen for empty history" "null" "$(jq -r '.current' "$STATS_CONTEXT_FILE")"

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
