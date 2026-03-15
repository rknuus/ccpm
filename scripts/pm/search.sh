#!/bin/bash

query="$1"

if [ -z "$query" ]; then
  echo "❌ Please provide a search query"
  echo "Usage: /ccpm:search <query>"
  exit 1
fi

echo "Searching for '$query'..."
echo ""
echo ""

echo "🔍 Search results for: '$query'"
echo "================================"
echo ""

# Search in Initiatives
if [ -d ".pm/initiatives" ]; then
  echo "📄 Initiatives:"
  results=$(grep -l -i "$query" .pm/initiatives/*.md 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      name=$(basename "$file" .md)
      matches=$(grep -c -i "$query" "$file")
      echo "  • $name ($matches matches)"
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Epics
if [ -d ".pm/initiatives" ]; then
  echo "📚 Epics:"
  results=$(find .pm/initiatives -name "epic.md" -exec grep -l -i "$query" {} \; 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      epic_name=$(basename $(dirname "$file"))
      matches=$(grep -c -i "$query" "$file")
      echo "  • $epic_name ($matches matches)"
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Tasks
if [ -d ".pm/initiatives" ]; then
  echo "📝 Tasks:"
  results=$(find .pm/initiatives -name "[0-9]*.md" -exec grep -l -i "$query" {} \; 2>/dev/null | head -10)
  if [ -n "$results" ]; then
    for file in $results; do
      epic_name=$(basename $(dirname "$file"))
      task_num=$(basename "$file" .md)
      echo "  • Task #$task_num in $epic_name"
    done
  else
    echo "  No matches"
  fi
fi

# Summary
total=$(find .claude -name "*.md" -exec grep -l -i "$query" {} \; 2>/dev/null | wc -l)
echo ""
echo "📊 Total files with matches: $total"

exit 0
