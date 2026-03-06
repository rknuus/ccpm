#!/bin/bash
# test-utility-scripts.sh — Tests for ccpm-datetime, ccpm-repo-check,
# and ccpm-strip-frontmatter utility scripts.
#
# Usage: bash tests/test-utility-scripts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DATETIME_SCRIPT="$PROJECT_ROOT/scripts/pm/ccpm-datetime.sh"
REPO_CHECK_SCRIPT="$PROJECT_ROOT/scripts/pm/ccpm-repo-check.sh"
STRIP_FM_SCRIPT="$PROJECT_ROOT/scripts/pm/ccpm-strip-frontmatter.sh"

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
echo "=== ccpm-repo-check.sh: exits 0 for non-template repo ==="
# =========================================================================
# Current repo is rknuus/ccpm, not automazeio/ccpm, so it should pass
rc_output=$(bash "$REPO_CHECK_SCRIPT" 2>&1) || true
rc_exit=$?
assert_eq "exit code is 0 for non-template repo" "0" "$rc_exit"

# =========================================================================
echo ""
echo "=== ccpm-repo-check.sh: exits 1 for template repo ==="
# =========================================================================
# Create a temporary git repo with automazeio/ccpm as origin
FAKE_REPO="$TMPDIR_TEST/fake-repo"
mkdir -p "$FAKE_REPO"
git -C "$FAKE_REPO" init -q
git -C "$FAKE_REPO" remote add origin "https://github.com/automazeio/ccpm.git"

rc_output=""
rc_exit=0
rc_output=$(cd "$FAKE_REPO" && bash "$REPO_CHECK_SCRIPT" 2>&1) || rc_exit=$?
assert_eq "exit code is 1 for template repo" "1" "$rc_exit"

# =========================================================================
echo ""
echo "=== ccpm-repo-check.sh: error output mentions template ==="
# =========================================================================
if echo "$rc_output" | grep -qi "template"; then
  echo "  PASS: error output mentions 'template'"
  passed=$((passed + 1))
else
  echo "  FAIL: error output should mention 'template'"
  echo "    actual: $rc_output"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-strip-frontmatter.sh: strips frontmatter from file ==="
# =========================================================================
FM_FILE="$TMPDIR_TEST/with-frontmatter.md"
cat > "$FM_FILE" <<'EOF'
---
name: test
status: open
created: 2026-01-01T00:00:00Z
---

# Title

Some content here.
EOF

stripped=$(bash "$STRIP_FM_SCRIPT" "$FM_FILE")
# Should not contain the YAML fields
if echo "$stripped" | grep -q "^name:"; then
  echo "  FAIL: frontmatter was not stripped (name: still present)"
  failed=$((failed + 1))
else
  echo "  PASS: frontmatter fields stripped"
  passed=$((passed + 1))
fi

# Should contain the body content
if echo "$stripped" | grep -q "# Title"; then
  echo "  PASS: body content preserved"
  passed=$((passed + 1))
else
  echo "  FAIL: body content missing after stripping"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-strip-frontmatter.sh: passes through file without frontmatter ==="
# =========================================================================
NO_FM_FILE="$TMPDIR_TEST/no-frontmatter.md"
cat > "$NO_FM_FILE" <<'EOF'
# Just a Title

No frontmatter in this file.
EOF

stripped=$(bash "$STRIP_FM_SCRIPT" "$NO_FM_FILE")
expected=$(cat "$NO_FM_FILE")
assert_eq "pass-through unchanged" "$expected" "$stripped"

# =========================================================================
echo ""
echo "=== ccpm-strip-frontmatter.sh: output file argument ==="
# =========================================================================
OUT_FILE="$TMPDIR_TEST/output.md"
bash "$STRIP_FM_SCRIPT" "$FM_FILE" "$OUT_FILE"

if [ -f "$OUT_FILE" ]; then
  echo "  PASS: output file created"
  passed=$((passed + 1))
else
  echo "  FAIL: output file was not created"
  failed=$((failed + 1))
fi

out_content=$(cat "$OUT_FILE")
if echo "$out_content" | grep -q "^name:"; then
  echo "  FAIL: output file still contains frontmatter"
  failed=$((failed + 1))
else
  echo "  PASS: output file has frontmatter stripped"
  passed=$((passed + 1))
fi

if echo "$out_content" | grep -q "Some content here"; then
  echo "  PASS: output file has body content"
  passed=$((passed + 1))
else
  echo "  FAIL: output file missing body content"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-strip-frontmatter.sh: missing argument gives usage error ==="
# =========================================================================
usage_output=""
usage_exit=0
usage_output=$(bash "$STRIP_FM_SCRIPT" 2>&1) || usage_exit=$?
assert_eq "exit code is 1 for missing argument" "1" "$usage_exit"

if echo "$usage_output" | grep -qi "usage"; then
  echo "  PASS: prints usage message"
  passed=$((passed + 1))
else
  echo "  FAIL: should print usage message"
  echo "    actual: $usage_output"
  failed=$((failed + 1))
fi

# =========================================================================
echo ""
echo "=== ccpm-strip-frontmatter.sh: missing file gives error ==="
# =========================================================================
missing_output=""
missing_exit=0
missing_output=$(bash "$STRIP_FM_SCRIPT" "$TMPDIR_TEST/nonexistent.md" 2>&1) || missing_exit=$?
assert_eq "exit code is 1 for missing file" "1" "$missing_exit"

if echo "$missing_output" | grep -qi "not found"; then
  echo "  PASS: prints file not found error"
  passed=$((passed + 1))
else
  echo "  FAIL: should print file not found error"
  echo "    actual: $missing_output"
  failed=$((failed + 1))
fi

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
