#!/bin/bash
# test-stats-prompts.sh — Tests for scripts/pm/stats-prompts.sh
#
# Usage: bash tests/test-stats-prompts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create a temporary directory for test isolation
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

FIXTURES="$SCRIPT_DIR/fixtures"
SESSION_1="$FIXTURES/session-1.jsonl"
SESSION_2="$FIXTURES/session-2.jsonl"

# Set up settings and context files in temp dir
STATS_SETTINGS_FILE="$TEST_DIR/.pm/ccpm-settings.json"
STATS_CONTEXT_FILE="$TEST_DIR/.pm/stats/active-context.json"
mkdir -p "$(dirname "$STATS_SETTINGS_FILE")"
mkdir -p "$(dirname "$STATS_CONTEXT_FILE")"

export STATS_SETTINGS_FILE STATS_CONTEXT_FILE

# Source dependencies
source "$PROJECT_ROOT/scripts/pm/stats-prompts.sh"

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

assert_file_exists() {
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  PASS: $label"
    passed=$((passed + 1))
  else
    echo "  FAIL: $label (file not found: $path)"
    failed=$((failed + 1))
  fi
}

assert_file_not_exists() {
  local label="$1" path="$2"
  if [ ! -f "$path" ]; then
    echo "  PASS: $label"
    passed=$((passed + 1))
  else
    echo "  FAIL: $label (file should not exist: $path)"
    failed=$((failed + 1))
  fi
}

# Override stats_find_jsonl_files to return our fixture files
stats_find_jsonl_files() {
  echo "$SESSION_1"
  echo "$SESSION_2"
}

# Helper: set up context history with known timestamps matching fixture data
setup_context_with_session1() {
  # Window covers session-1: 10:00:00 to 10:00:35
  jq -n '{
    "current": null,
    "history": [{
      "type": "epic",
      "name": "test-epic",
      "command": "epic-start",
      "started": "2026-02-15T09:59:00Z",
      "ended": "2026-02-15T10:01:00Z"
    }]
  }' > "$STATS_CONTEXT_FILE"
}

setup_context_with_two_windows() {
  # Two windows: one covering session-1, one covering session-2
  jq -n '{
    "current": null,
    "history": [{
      "type": "epic",
      "name": "test-epic",
      "command": "epic-start",
      "started": "2026-02-15T09:59:00Z",
      "ended": "2026-02-15T10:01:00Z"
    },{
      "type": "epic",
      "name": "test-epic",
      "command": "issue-start",
      "started": "2026-02-15T10:59:00Z",
      "ended": "2026-02-15T11:01:00Z"
    }]
  }' > "$STATS_CONTEXT_FILE"
}

# Use temp dir as working directory for .pm/stats/ output
cd "$TEST_DIR"

# =========================================================================
echo ""
echo "=== Test 1: Disabled by default (collectPrompts = false) ==="
# =========================================================================
echo '{"collectPrompts": false}' > "$STATS_SETTINGS_FILE"
setup_context_with_session1
stats_collect_prompts "epic" "test-epic"
assert_file_not_exists "no prompts dir when disabled" "$TEST_DIR/.pm/stats/epics/test-epic/prompts/session-2026-02-15T09-59-00Z.txt"

# =========================================================================
echo ""
echo "=== Test 2: Enabled collects prompts ==="
# =========================================================================
echo '{"collectPrompts": true}' > "$STATS_SETTINGS_FILE"
setup_context_with_session1
stats_collect_prompts "epic" "test-epic"

PROMPT_FILE="$TEST_DIR/.pm/stats/epics/test-epic/prompts/session-2026-02-15T09-59-00Z.txt"
assert_file_exists "prompt file created" "$PROMPT_FILE"

# Check header line
header="$(head -1 "$PROMPT_FILE")"
assert_eq "header format" "# Prompts for epic/test-epic — Session 2026-02-15T09:59:00Z" "$header"

# Check that user prompts are present (3 from session-1 + 2 from session-2 within window)
# Window is 09:59:00 to 10:01:00 — covers session-1 prompts (10:00:00, 10:00:15, 10:00:35)
# Session-2 is at 11:00:xx — outside this window
prompt_sections=$(grep -c '^\## \[' "$PROMPT_FILE")
assert_eq "prompt count in file" "3" "$prompt_sections"

# Check that first prompt text is present
if grep -q "Implement the login feature" "$PROMPT_FILE"; then
  echo "  PASS: first prompt text present"
  passed=$((passed + 1))
else
  echo "  FAIL: first prompt text not found"
  failed=$((failed + 1))
fi

# Check that tool result is excluded
if grep -q "file written" "$PROMPT_FILE"; then
  echo "  FAIL: tool result should be excluded"
  failed=$((failed + 1))
else
  echo "  PASS: tool result excluded"
  passed=$((passed + 1))
fi

# =========================================================================
echo ""
echo "=== Test 3: Idempotent — does not overwrite existing prompt file ==="
# =========================================================================
# Modify the file content so we can detect if it gets overwritten
echo "MARKER" >> "$PROMPT_FILE"
stats_collect_prompts "epic" "test-epic"
if grep -q "MARKER" "$PROMPT_FILE"; then
  echo "  PASS: file not overwritten (idempotent)"
  passed=$((passed + 1))
else
  echo "  FAIL: file was overwritten"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== Test 4: Multiple context windows ==="
# =========================================================================
# Clean up previous test
rm -rf "$TEST_DIR/.pm/stats/epics"
setup_context_with_two_windows
stats_collect_prompts "epic" "test-epic"

PROMPT_FILE_1="$TEST_DIR/.pm/stats/epics/test-epic/prompts/session-2026-02-15T09-59-00Z.txt"
PROMPT_FILE_2="$TEST_DIR/.pm/stats/epics/test-epic/prompts/session-2026-02-15T10-59-00Z.txt"

assert_file_exists "first window prompt file" "$PROMPT_FILE_1"
assert_file_exists "second window prompt file" "$PROMPT_FILE_2"

# First window: 3 prompts from session-1
prompt_count_1=$(grep -c '^\## \[' "$PROMPT_FILE_1")
assert_eq "first window prompt count" "3" "$prompt_count_1"

# Second window: 2 prompts from session-2 (11:00:00 to 11:01:00)
prompt_count_2=$(grep -c '^\## \[' "$PROMPT_FILE_2")
assert_eq "second window prompt count" "2" "$prompt_count_2"

# =========================================================================
echo ""
echo "=== Test 5: No context history — no files created ==="
# =========================================================================
rm -rf "$TEST_DIR/.pm/stats/epics"
jq -n '{"current": null, "history": []}' > "$STATS_CONTEXT_FILE"
stats_collect_prompts "epic" "no-history"
assert_file_not_exists "no prompts dir for empty history" "$TEST_DIR/.pm/stats/epics/no-history/prompts"

# =========================================================================
echo ""
echo "=== Test 6: Missing settings file — treated as disabled ==="
# =========================================================================
rm -f "$STATS_SETTINGS_FILE"
rm -rf "$TEST_DIR/.pm/stats/epics"
setup_context_with_session1
stats_collect_prompts "epic" "test-epic"
assert_file_not_exists "no prompts when settings missing" "$TEST_DIR/.pm/stats/epics/test-epic/prompts/session-2026-02-15T09-59-00Z.txt"

# =========================================================================
echo ""
echo "=== Test 7: Empty arguments — safe no-op ==="
# =========================================================================
echo '{"collectPrompts": true}' > "$STATS_SETTINGS_FILE"
stats_collect_prompts "" ""
# Should not error — just return

echo "  PASS: empty arguments handled safely"
passed=$((passed + 1))

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
