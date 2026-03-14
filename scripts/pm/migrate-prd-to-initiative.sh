#!/bin/bash
set -euo pipefail

# Migration script: PRD -> Initiative terminology
# Migrates user data in .pm/ directory

# Find project root (where .pm/ lives)
PM_DIR="${PM_DIR:-.pm}"

moved_count=0
updated_count=0
skipped_count=0

# Step 1: Move .pm/prds/ -> .pm/initiatives/
if [ -d "$PM_DIR/prds" ]; then
  if [ -d "$PM_DIR/initiatives" ]; then
    echo "ℹ️ .pm/initiatives/ already exists — skipping directory move"
  else
    mv "$PM_DIR/prds" "$PM_DIR/initiatives"
    moved_count=$(find "$PM_DIR/initiatives" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ Moved .pm/prds/ -> .pm/initiatives/ ($moved_count files)"
  fi
elif [ -d "$PM_DIR/initiatives" ]; then
  echo "ℹ️ Already migrated — .pm/initiatives/ exists, .pm/prds/ does not"
else
  echo "ℹ️ No .pm/prds/ directory found — nothing to migrate"
  exit 0
fi

# Step 2: Update epic frontmatter references
if [ -d "$PM_DIR/epics" ]; then
  for epic_file in "$PM_DIR"/epics/*/epic.md; do
    [ -f "$epic_file" ] || continue

    # Check if epic is in-progress — skip if so
    local_status=$(grep '^status:' "$epic_file" | head -1 | sed 's/^status: *//')
    if [ "$local_status" = "in-progress" ]; then
      skipped_count=$((skipped_count + 1))
      echo "⏭️ Skipped $(basename "$(dirname "$epic_file")")/epic.md (in-progress)"
      continue
    fi

    # Check if file contains prd: references that need updating
    if grep -q '^prd:' "$epic_file" 2>/dev/null; then
      # Replace prd: with initiative: in frontmatter (cross-platform)
      tmp_file=$(mktemp)
      sed 's/^prd: *\.pm\/prds\//initiative: .pm\/initiatives\//' "$epic_file" > "$tmp_file"
      mv "$tmp_file" "$epic_file"
      # Handle any remaining prd: lines not matching the path pattern
      tmp_file=$(mktemp)
      sed 's/^prd: */initiative: /' "$epic_file" > "$tmp_file"
      mv "$tmp_file" "$epic_file"
      updated_count=$((updated_count + 1))
      echo "✅ Updated $(basename "$(dirname "$epic_file")")/epic.md"
    fi
  done
fi

echo ""
echo "Migration complete:"
echo "  Files moved: $moved_count"
echo "  Epics updated: $updated_count"
echo "  Epics skipped (in-progress): $skipped_count"
