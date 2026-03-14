# !/bin/bash
# Check if Initiative directory exists
if [ ! -d ".pm/initiatives" ]; then
  echo "No Initiative directory found. Create your first Initiative with: /ccpm:initiative-new <feature-name>"
  exit 0
fi

# Check for Initiative files
if ! ls .pm/initiatives/*.md >/dev/null 2>&1; then
  echo "No Initiatives found. Create your first Initiative with: /ccpm:initiative-new <feature-name>"
  exit 0
fi

# Initialize counters
backlog_count=0
in_progress_count=0
implemented_count=0
total_count=0

echo "Getting Initiatives..."
echo ""
echo ""


echo "Initiative List"
echo "==========="
echo ""

# Display by status groups
echo "Backlog Initiatives:"
for file in .pm/initiatives/*.md; do
  [ -f "$file" ] || continue
  status=$(grep "^status:" "$file" | head -1 | sed 's/^status: *//')
  if [ "$status" = "backlog" ] || [ "$status" = "draft" ] || [ -z "$status" ]; then
    name=$(grep "^name:" "$file" | head -1 | sed 's/^name: *//')
    desc=$(grep "^description:" "$file" | head -1 | sed 's/^description: *//')
    [ -z "$name" ] && name=$(basename "$file" .md)
    [ -z "$desc" ] && desc="No description"
    # echo "   $name - $desc"
    echo "   $file - $desc"
    ((backlog_count++))
  fi
  ((total_count++))
done
[ $backlog_count -eq 0 ] && echo "   (none)"

echo ""
echo "In-Progress Initiatives:"
for file in .pm/initiatives/*.md; do
  [ -f "$file" ] || continue
  status=$(grep "^status:" "$file" | head -1 | sed 's/^status: *//')
  if [ "$status" = "in-progress" ] || [ "$status" = "active" ]; then
    name=$(grep "^name:" "$file" | head -1 | sed 's/^name: *//')
    desc=$(grep "^description:" "$file" | head -1 | sed 's/^description: *//')
    [ -z "$name" ] && name=$(basename "$file" .md)
    [ -z "$desc" ] && desc="No description"
    # echo "   $name - $desc"
    echo "   $file - $desc"
    ((in_progress_count++))
  fi
done
[ $in_progress_count -eq 0 ] && echo "   (none)"

echo ""
echo "Implemented Initiatives:"
for file in .pm/initiatives/*.md; do
  [ -f "$file" ] || continue
  status=$(grep "^status:" "$file" | head -1 | sed 's/^status: *//')
  if [ "$status" = "implemented" ] || [ "$status" = "completed" ] || [ "$status" = "done" ]; then
    name=$(grep "^name:" "$file" | head -1 | sed 's/^name: *//')
    desc=$(grep "^description:" "$file" | head -1 | sed 's/^description: *//')
    [ -z "$name" ] && name=$(basename "$file" .md)
    [ -z "$desc" ] && desc="No description"
    # echo "   $name - $desc"
    echo "   $file - $desc"
    ((implemented_count++))
  fi
done
[ $implemented_count -eq 0 ] && echo "   (none)"

# Display summary
echo ""
echo "Initiative Summary"
echo "   Total Initiatives: $total_count"
echo "   Backlog: $backlog_count"
echo "   In-Progress: $in_progress_count"
echo "   Implemented: $implemented_count"

exit 0
