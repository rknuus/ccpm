#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths-lib.sh"

echo "Validating PM System..."
echo ""
echo ""

echo "🔍 Validating PM System"
echo "======================="
echo ""

errors=0
warnings=0

# Check directory structure
echo "📁 Directory Structure:"
[ -d ".claude" ] && echo "  ✅ .claude directory exists" || { echo "  ❌ .claude directory missing"; ((errors++)); }
[ -d ".pm/initiatives" ] && echo "  ✅ Initiatives directory exists" || echo "  ⚠️ Initiatives directory missing"
[ -d ".pm/epics" ] && echo "  ✅ Epics directory (old layout) exists" || echo "  ℹ️ No old .pm/epics directory (ok if using new layout)"
[ -d ".claude/rules" ] && echo "  ✅ Rules directory exists" || echo "  ⚠️ Rules directory missing"
echo ""

# Check for orphaned files
echo "🗂️ Data Integrity:"

# Check epics have epic.md files — both layouts
for epic_dir in .pm/initiatives/*/*/ .pm/epics/*/; do
  [ -d "$epic_dir" ] || continue
  if [ ! -f "$epic_dir/epic.md" ]; then
    echo "  ⚠️ Missing epic.md in $(basename "$epic_dir")"
    ((warnings++))
  fi
done

# Check for tasks without epics
orphaned=$(find .claude -name "[0-9]*.md" -not -path ".pm/initiatives/*" -not -path ".pm/epics/*" 2>/dev/null | wc -l)
[ $orphaned -gt 0 ] && echo "  ⚠️ Found $orphaned orphaned task files" && ((warnings++))

# Check for broken references
echo ""
echo "🔗 Reference Check:"

for task_file in .pm/initiatives/*/*/[0-9]*.md .pm/epics/*/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  # Extract dependencies from task file
  deps_line=$(grep "^depends_on:" "$task_file" | head -1)
  if [ -n "$deps_line" ]; then
    deps=$(echo "$deps_line" | sed 's/^depends_on: *//')
    deps=$(echo "$deps" | sed 's/^\[//' | sed 's/\]$//')
    deps=$(echo "$deps" | sed 's/,/ /g')
    # Trim whitespace and handle empty cases
    deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$deps" ] && deps=""
  else
    deps=""
  fi
  if [ -n "$deps" ] && [ "$deps" != "depends_on:" ]; then
    epic_dir=$(dirname "$task_file")
    for dep in $deps; do
      if [ ! -f "$epic_dir/$dep.md" ]; then
        echo "  ⚠️ Task $(basename "$task_file" .md) references missing task: $dep"
        ((warnings++))
      fi
    done
  fi
done

if [ $warnings -eq 0 ] && [ $errors -eq 0 ]; then
  echo "  ✅ All references valid"
fi

# Check frontmatter
echo ""
echo "📝 Frontmatter Validation:"
invalid=0

for file in $(find .pm -name "*.md" -path "*/initiatives/*" 2>/dev/null; find .pm -name "*.md" -path "*/epics/*" 2>/dev/null); do
  if ! grep -q "^---" "$file"; then
    echo "  ⚠️ Missing frontmatter: $(basename "$file")"
    ((invalid++))
  fi
done

[ $invalid -eq 0 ] && echo "  ✅ All files have frontmatter"

# Summary
echo ""
echo "📊 Validation Summary:"
echo "  Errors: $errors"
echo "  Warnings: $warnings"
echo "  Invalid files: $invalid"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ] && [ $invalid -eq 0 ]; then
  echo ""
  echo "✅ System is healthy!"
else
  echo ""
  echo "💡 Run /ccpm:clean to fix some issues automatically"
fi

exit 0
