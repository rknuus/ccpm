#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths-lib.sh"

echo "Getting epics..."
echo ""
echo ""

# Collect epic directories
epic_dirs=""
for f in .pm/initiatives/*/*/epic.md; do
  [ -f "$f" ] && epic_dirs="${epic_dirs}$(dirname "$f")/
"
done
if [ -z "$epic_dirs" ]; then
  echo "📁 No epics found. Create your first epic with: /ccpm:initiative-decompose <feature-name>"
  exit 0
fi

echo "📚 Project Epics"
echo "================"
echo ""

# Initialize arrays to store epics by status
planning_epics=""
in_progress_epics=""
completed_epics=""

# Process all epics
echo "$epic_dirs" | while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  [ -d "$dir" ] || continue
  [ -f "$dir/epic.md" ] || continue

  # Extract metadata
  n=$(grep "^name:" "$dir/epic.md" | head -1 | sed 's/^name: *//')
  s=$(grep "^status:" "$dir/epic.md" | head -1 | sed 's/^status: *//' | tr '[:upper:]' '[:lower:]')
  p=$(grep "^progress:" "$dir/epic.md" | head -1 | sed 's/^progress: *//')
  # Defaults
  [ -z "$n" ] && n=$(basename "$dir")
  [ -z "$p" ] && p="0%"

  # Count tasks
  t=$(ls "$dir"/[0-9]*.md 2>/dev/null | wc -l)

  entry="   📋 ${dir}epic.md - $p complete ($t tasks)"

  # Categorize by status (handle various status values)
  case "$s" in
    planning|draft|"")
      echo "PLANNING:${entry}"
      ;;
    in-progress|in_progress|active|started)
      echo "INPROGRESS:${entry}"
      ;;
    completed|complete|done|closed|finished)
      echo "COMPLETED:${entry}"
      ;;
    *)
      echo "PLANNING:${entry}"
      ;;
  esac
done | {
  planning_epics=""
  in_progress_epics=""
  completed_epics=""

  while IFS= read -r line; do
    case "$line" in
      PLANNING:*)   planning_epics="${planning_epics}${line#PLANNING:}\n" ;;
      INPROGRESS:*) in_progress_epics="${in_progress_epics}${line#INPROGRESS:}\n" ;;
      COMPLETED:*)  completed_epics="${completed_epics}${line#COMPLETED:}\n" ;;
    esac
  done

  # Display categorized epics
  echo "📝 Planning:"
  if [ -n "$planning_epics" ]; then
    echo -e "$planning_epics" | sed '/^$/d'
  else
    echo "   (none)"
  fi

  echo ""
  echo "🚀 In Progress:"
  if [ -n "$in_progress_epics" ]; then
    echo -e "$in_progress_epics" | sed '/^$/d'
  else
    echo "   (none)"
  fi

  echo ""
  echo "✅ Completed:"
  if [ -n "$completed_epics" ]; then
    echo -e "$completed_epics" | sed '/^$/d'
  else
    echo "   (none)"
  fi
}

# Summary
echo ""
echo "📊 Summary"
total=0
tasks=0
for f in .pm/initiatives/*/*/epic.md; do
  [ -f "$f" ] && ((total++)) || true
done
tasks=$(find .pm/initiatives -name "[0-9]*.md" 2>/dev/null | wc -l)
echo "   Total epics: $total"
echo "   Total tasks: $tasks"

exit 0
