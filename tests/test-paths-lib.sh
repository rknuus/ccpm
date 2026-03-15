#!/bin/bash
# Tests for scripts/pm/paths-lib.sh
# Run from project root: bash tests/test-paths-lib.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Use a temporary directory so we don't touch real project data
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Source the library under test
source "$PROJECT_ROOT/scripts/pm/paths-lib.sh"

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

# ─── Test 1: Simple path functions ───

echo "Test 1: Simple path functions return correct paths"
assert_eq "pm_initiative_file" ".pm/initiatives/auth.md" "$(pm_initiative_file "auth")"
assert_eq "pm_initiative_dir" ".pm/initiatives/auth/" "$(pm_initiative_dir "auth")"
assert_eq "pm_epic_dir" ".pm/initiatives/auth/login-flow/" "$(pm_epic_dir "auth" "login-flow")"
assert_eq "pm_epic_file" ".pm/initiatives/auth/login-flow/epic.md" "$(pm_epic_file "auth" "login-flow")"
assert_eq "pm_task_file" ".pm/initiatives/auth/login-flow/42.md" "$(pm_task_file "auth" "login-flow" "42")"

# ─── Test 2: pm_find_epic returns new-layout path when epic exists ───

echo ""
echo "Test 2: pm_find_epic finds epic in new layout"
cd "$TEST_DIR"
mkdir -p .pm/initiatives/auth/login-flow
echo "---" > .pm/initiatives/auth/login-flow/epic.md

result="$(pm_find_epic "login-flow")"
assert_eq "new-layout epic found" ".pm/initiatives/auth/login-flow/" "$result"

# ─── Test 3: pm_find_epic falls back to old layout ───

echo ""
echo "Test 3: pm_find_epic falls back to old layout"
cd "$TEST_DIR"
rm -rf .pm
mkdir -p .pm/epics/legacy-epic

result="$(pm_find_epic "legacy-epic")"
assert_eq "old-layout epic found" ".pm/epics/legacy-epic/" "$result"

# ─── Test 4: pm_find_epic returns default new-layout path when epic not found ───

echo ""
echo "Test 4: pm_find_epic returns default path when epic doesn't exist"
cd "$TEST_DIR"
rm -rf .pm
mkdir -p .pm/initiatives/my-project

result="$(pm_find_epic "new-epic")"
assert_eq "default new-layout path" ".pm/initiatives/my-project/new-epic/" "$result"

# ─── Test 5: pm_find_epic prefers new layout over old ───

echo ""
echo "Test 5: pm_find_epic prefers new layout when both exist"
cd "$TEST_DIR"
rm -rf .pm
mkdir -p .pm/initiatives/auth/shared-epic
echo "---" > .pm/initiatives/auth/shared-epic/epic.md
mkdir -p .pm/epics/shared-epic

result="$(pm_find_epic "shared-epic")"
assert_eq "new layout preferred" ".pm/initiatives/auth/shared-epic/" "$result"

# ─── Test 6: pm_find_epic with no initiatives defaults to epic/epic ───

echo ""
echo "Test 6: pm_find_epic with no initiatives falls back to epic-name default"
cd "$TEST_DIR"
rm -rf .pm
mkdir -p .pm

result="$(pm_find_epic "orphan-epic")"
assert_eq "fallback to epic/epic" ".pm/initiatives/orphan-epic/orphan-epic/" "$result"

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
