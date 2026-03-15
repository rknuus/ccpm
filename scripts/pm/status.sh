#!/bin/bash

echo "Getting status..."
echo ""
echo ""


echo "📊 Project Status"
echo "================"
echo ""

echo "📄 Initiatives:"
if [ -d ".pm/initiatives" ]; then
  total=$(ls .pm/initiatives/*.md 2>/dev/null | wc -l)
  echo "  Total: $total"
else
  echo "  No Initiatives found"
fi

echo ""
echo "📚 Epics:"
if [ -d ".pm/initiatives" ]; then
  active=$(find .pm/initiatives -name "epic.md" -not -path "*/archived/*" -not -path "*/.archived/*" 2>/dev/null | wc -l)
  archived=$(find .pm/initiatives -path "*/archived/*/epic.md" -o -path "*/.archived/*/epic.md" 2>/dev/null | wc -l)
  echo "  Active: $active"
  echo "  Archived: $archived"
else
  echo "  No epics found"
fi

echo ""
echo "📝 Tasks:"
if [ -d ".pm/initiatives" ]; then
  total=$(find .pm/initiatives -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" 2>/dev/null | wc -l)
  open=$(find .pm/initiatives -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l)
  closed=$(find .pm/initiatives -name "[0-9]*.md" -not -path "*/archived/*" -not -path "*/.archived/*" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
  echo "  Open: $open"
  echo "  Closed: $closed"
  echo "  Total: $total"
else
  echo "  No tasks found"
fi

exit 0
