#!/bin/bash
# test-utility-scripts.sh — Tests for ccpm-datetime and ccpm-git-commit
# utility scripts.
#
# Usage: bash tests/test-utility-scripts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DATETIME_SCRIPT="$PROJECT_ROOT/scripts/pm/ccpm-datetime.sh"

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

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# =========================================================================
echo ""
echo "=== ccpm-datetime.sh: output matches ISO 8601 format ==="
# =========================================================================
dt_output=$(bash "$DATETIME_SCRIPT")
if [[ "$dt_output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  echo "  PASS: output matches ISO 8601 format ($dt_output)"
  passed=$((passed + 1))
else
  echo "  FAIL: output does not match ISO 8601 format"
  echo "    actual: $dt_output"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-datetime.sh: exits with code 0 ==="
# =========================================================================
bash "$DATETIME_SCRIPT" > /dev/null 2>&1
dt_exit=$?
assert_eq "exit code is 0" "0" "$dt_exit"

# =========================================================================
echo ""
echo "=== ccpm-git-commit.sh: missing argument gives usage error ==="
# =========================================================================
GIT_COMMIT_SCRIPT="$PROJECT_ROOT/scripts/pm/ccpm-git-commit.sh"

gc_output=""
gc_exit=0
gc_output=$(bash "$GIT_COMMIT_SCRIPT" 2>&1) || gc_exit=$?
assert_eq "exit code is 1 for missing argument" "1" "$gc_exit"

if echo "$gc_output" | grep -qi "usage"; then
  echo "  PASS: prints usage message"
  passed=$((passed + 1))
else
  echo "  FAIL: should print usage message"
  echo "    actual: $gc_output"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-git-commit.sh: missing message file gives error ==="
# =========================================================================
gc_output=""
gc_exit=0
gc_output=$(bash "$GIT_COMMIT_SCRIPT" "$TMPDIR_TEST/nonexistent-msg.txt" 2>&1) || gc_exit=$?
assert_eq "exit code is 1 for missing message file" "1" "$gc_exit"

if echo "$gc_output" | grep -qi "not found"; then
  echo "  PASS: prints message file not found error"
  passed=$((passed + 1))
else
  echo "  FAIL: should print message file not found error"
  echo "    actual: $gc_output"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-git-commit.sh: commits with message from file ==="
# =========================================================================
# Create a temporary git repo to test actual commits
COMMIT_REPO="$TMPDIR_TEST/commit-repo"
mkdir -p "$COMMIT_REPO"
git -C "$COMMIT_REPO" init -q
git -C "$COMMIT_REPO" config user.email "test@test.com"
git -C "$COMMIT_REPO" config user.name "Test"

# Create a file and an initial commit
echo "initial" > "$COMMIT_REPO/file.txt"
git -C "$COMMIT_REPO" add file.txt
git -C "$COMMIT_REPO" commit -q -m "initial"

# Now test the script
echo "modified" > "$COMMIT_REPO/file.txt"
MSG_FILE="$TMPDIR_TEST/commit-msg.txt"
echo "Test commit message" > "$MSG_FILE"

gc_exit=0
(cd "$COMMIT_REPO" && bash "$GIT_COMMIT_SCRIPT" "$MSG_FILE" file.txt) > /dev/null 2>&1 || gc_exit=$?
assert_eq "exit code is 0 for successful commit" "0" "$gc_exit"

# Verify the commit message
last_msg=$(git -C "$COMMIT_REPO" log -1 --format=%s)
assert_eq "commit message matches" "Test commit message" "$last_msg"

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
