#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths-lib.sh"

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Please provide an epic name"
  echo "Usage: /ccpm:epic-show <epic-name>"
  exit 1
fi

echo "Getting epic..."
echo ""
echo ""

epic_dir="$(pm_find_epic "$epic_name")"
epic_file="${epic_dir}epic.md"

if [ ! -f "$epic_file" ]; then
  echo "❌ Epic not found: $epic_name"
  echo ""
  echo "Available epics:"
  for f in .pm/initiatives/*/*/epic.md; do
    [ -f "$f" ] && echo "  • $(basename "$(dirname "$f")")"
  done
  for dir in .pm/epics/*/; do
    [ -d "$dir" ] && echo "  • $(basename "$dir")"
  done
  exit 1
fi

# Display epic details
echo "📚 Epic: $epic_name"
echo "================================"
echo ""

# Extract metadata
status=$(grep "^status:" "$epic_file" | head -1 | sed 's/^status: *//')
progress=$(grep "^progress:" "$epic_file" | head -1 | sed 's/^progress: *//')
created=$(grep "^created:" "$epic_file" | head -1 | sed 's/^created: *//')

echo "📊 Metadata:"
echo "  Status: ${status:-planning}"
echo "  Progress: ${progress:-0%}"
echo "  Created: ${created:-unknown}"
echo ""

# Show tasks
echo "📝 Tasks:"
task_count=0
open_count=0
closed_count=0

for task_file in "$epic_dir"/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  task_num=$(basename "$task_file" .md)
  task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
  task_status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
  parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')

  if [ "$task_status" = "closed" ] || [ "$task_status" = "completed" ]; then
    echo "  ✅ #$task_num - $task_name"
    ((closed_count++))
  else
    echo "  ⬜ #$task_num - $task_name"
    [ "$parallel" = "true" ] && echo -n " (parallel)"
    ((open_count++))
  fi

  ((task_count++))
done

if [ $task_count -eq 0 ]; then
  echo "  No tasks created yet"
  echo "  Run: /ccpm:epic-decompose $epic_name"
fi

echo ""
echo "📈 Statistics:"
echo "  Total tasks: $task_count"
echo "  Open: $open_count"
echo "  Closed: $closed_count"
[ $task_count -gt 0 ] && echo "  Completion: $((closed_count * 100 / task_count))%"

# Next actions
echo ""
echo "💡 Actions:"
[ $task_count -eq 0 ] && echo "  • Decompose into tasks: /ccpm:epic-decompose $epic_name"
[ $task_count -gt 0 ] && [ "$status" != "completed" ] && echo "  • Start work: /ccpm:epic-start $epic_name"

exit 0
