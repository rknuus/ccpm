#!/bin/bash

echo "Getting status..."
echo ""
echo ""


echo "📊 Project Status"
echo "================"
echo ""

echo "📄 PRDs:"
if [ -d ".pm/prds" ]; then
  total=$(ls .pm/prds/*.md 2>/dev/null | wc -l)
  echo "  Total: $total"
else
  echo "  No PRDs found"
fi

echo ""
echo "📚 Epics:"
if [ -d ".pm/epics" ]; then
  active=$(find .pm/epics -maxdepth 2 -name "epic.md" -not -path "*/archived/*" -not -path "*/.archived/*" 2>/dev/null | wc -l)
  archived=$(find .pm/epics -path "*/archived/*/epic.md" -o -path "*/.archived/*/epic.md" 2>/dev/null | wc -l)
  echo "  Active: $active"
  echo "  Archived: $archived"
else
  echo "  No epics found"
fi

echo ""
echo "📝 Tasks:"
if [ -d ".pm/epics" ]; then
  total=$(find .pm/epics -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" 2>/dev/null | wc -l)
  open=$(find .pm/epics -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l)
  closed=$(find .pm/epics -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
  echo "  Open: $open"
  echo "  Closed: $closed"
  echo "  Total: $total"
else
  echo "  No tasks found"
fi

exit 0
