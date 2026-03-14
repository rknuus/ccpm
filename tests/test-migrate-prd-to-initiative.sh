#!/bin/bash
# test-migrate-prd-to-initiative.sh — Tests for scripts/pm/migrate-prd-to-initiative.sh
#
# Usage: bash tests/test-migrate-prd-to-initiative.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATE_SCRIPT="$PROJECT_ROOT/scripts/pm/migrate-prd-to-initiative.sh"

# Create a temporary working directory to isolate tests
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

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
echo "=== Scenario 1: Fresh migration ==="
# =========================================================================

# Set up test data
mkdir -p "$TEST_DIR/s1/.pm/prds"
cat > "$TEST_DIR/s1/.pm/prds/foo.md" <<'EOF'
---
name: foo
status: backlog
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

# Foo Initiative
EOF

cat > "$TEST_DIR/s1/.pm/prds/bar.md" <<'EOF'
---
name: bar
status: backlog
created: 2026-01-02T00:00:00Z
updated: 2026-01-02T00:00:00Z
---

# Bar Initiative
EOF

mkdir -p "$TEST_DIR/s1/.pm/epics/foo"
cat > "$TEST_DIR/s1/.pm/epics/foo/epic.md" <<'EOF'
---
name: foo
prd: .pm/prds/foo.md
status: backlog
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

# Foo Epic
EOF

output=$(PM_DIR="$TEST_DIR/s1/.pm" bash "$MIGRATE_SCRIPT" 2>&1)

assert_eq "prds dir no longer exists" "false" "$([ -d "$TEST_DIR/s1/.pm/prds" ] && echo true || echo false)"
assert_eq "initiatives dir exists" "true" "$([ -d "$TEST_DIR/s1/.pm/initiatives" ] && echo true || echo false)"
assert_eq "foo.md moved" "true" "$([ -f "$TEST_DIR/s1/.pm/initiatives/foo.md" ] && echo true || echo false)"
assert_eq "bar.md moved" "true" "$([ -f "$TEST_DIR/s1/.pm/initiatives/bar.md" ] && echo true || echo false)"
assert_contains "output shows moved" "Moved .pm/prds/" "$output"
assert_contains "output shows 2 files" "2 files" "$output"

# Check epic frontmatter updated
epic_content=$(cat "$TEST_DIR/s1/.pm/epics/foo/epic.md")
assert_contains "epic has initiative key" "initiative:" "$epic_content"
assert_contains "epic references initiatives dir" ".pm/initiatives/foo.md" "$epic_content"
assert_not_contains "epic no longer has prd key" "prd:" "$epic_content"

# =========================================================================
echo ""
echo "=== Scenario 2: Idempotent re-run ==="
# =========================================================================

output=$(PM_DIR="$TEST_DIR/s1/.pm" bash "$MIGRATE_SCRIPT" 2>&1)

assert_eq "initiatives dir still exists" "true" "$([ -d "$TEST_DIR/s1/.pm/initiatives" ] && echo true || echo false)"
assert_eq "foo.md still present" "true" "$([ -f "$TEST_DIR/s1/.pm/initiatives/foo.md" ] && echo true || echo false)"
assert_eq "bar.md still present" "true" "$([ -f "$TEST_DIR/s1/.pm/initiatives/bar.md" ] && echo true || echo false)"
assert_contains "output shows already migrated" "Already migrated" "$output"

# Verify epic frontmatter still correct
epic_content=$(cat "$TEST_DIR/s1/.pm/epics/foo/epic.md")
assert_contains "epic still has initiative key" "initiative:" "$epic_content"
assert_not_contains "epic still no prd key" "prd:" "$epic_content"

# =========================================================================
echo ""
echo "=== Scenario 3: No .pm/prds/ directory (no-op) ==="
# =========================================================================

mkdir -p "$TEST_DIR/s3/.pm"
output=$(PM_DIR="$TEST_DIR/s3/.pm" bash "$MIGRATE_SCRIPT" 2>&1)
exit_code=$?

assert_eq "exits cleanly" "0" "$exit_code"
assert_contains "output shows nothing to migrate" "nothing to migrate" "$output"

# =========================================================================
echo ""
echo "=== Scenario 4: In-progress epic skipped ==="
# =========================================================================

mkdir -p "$TEST_DIR/s4/.pm/prds"
cat > "$TEST_DIR/s4/.pm/prds/bar.md" <<'EOF'
---
name: bar
status: backlog
---

# Bar Initiative
EOF

mkdir -p "$TEST_DIR/s4/.pm/epics/bar"
cat > "$TEST_DIR/s4/.pm/epics/bar/epic.md" <<'EOF'
---
name: bar
prd: .pm/prds/bar.md
status: in-progress
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

# Bar Epic
EOF

output=$(PM_DIR="$TEST_DIR/s4/.pm" bash "$MIGRATE_SCRIPT" 2>&1)

# Directory should still be moved
assert_eq "prds dir moved" "false" "$([ -d "$TEST_DIR/s4/.pm/prds" ] && echo true || echo false)"
assert_eq "initiatives dir exists" "true" "$([ -d "$TEST_DIR/s4/.pm/initiatives" ] && echo true || echo false)"

# But in-progress epic should NOT be updated
epic_content=$(cat "$TEST_DIR/s4/.pm/epics/bar/epic.md")
assert_contains "in-progress epic still has prd key" "prd:" "$epic_content"
assert_not_contains "in-progress epic not updated to initiative" "initiative:" "$epic_content"
assert_contains "output shows skipped" "Skipped" "$output"
assert_contains "output shows in-progress" "in-progress" "$output"

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================"
echo "Results: $passed passed, $failed failed"
echo "================================"

[ "$failed" -eq 0 ] && exit 0 || exit 1
