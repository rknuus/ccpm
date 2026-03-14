---
allowed-tools: Read, LS
---

# Epic Oneshot

Decompose epic into tasks and sync to GitHub in one operation.

## Usage
```
/ccpm:epic-oneshot <feature_name>
```

## Instructions

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`):
1. Check `.pm/initiatives/*/$ARGUMENTS/epic.md` (new layout)
2. Fall back to `.pm/epics/$ARGUMENTS/epic.md` (old layout)
Use the first path found.

### 1. Validate Prerequisites

Check that epic exists and hasn't been processed:
```bash
# Epic must exist
test -f {epic_dir}/epic.md || echo "❌ Epic not found. Run: /ccpm:initiative-parse $ARGUMENTS"

# Check for existing tasks
if ls {epic_dir}/[0-9]*.md 2>/dev/null | grep -q .; then
  echo "⚠️ Tasks already exist. This will create duplicates."
  echo "Delete existing tasks or use /ccpm:epic-sync instead."
  exit 1
fi

# Check if already synced
if grep -q "github:" {epic_dir}/epic.md; then
  echo "⚠️ Epic already synced to GitHub."
  echo "Use /ccpm:epic-sync to update."
  exit 1
fi
```

### 2. Execute Decompose

Simply run the decompose command:
```
Running: /ccpm:epic-decompose $ARGUMENTS
```

This will:
- Read the epic
- Create task files (using parallel agents if appropriate)
- Update epic with task summary

### 3. Execute Sync

Immediately follow with sync:
```
Running: /ccpm:epic-sync $ARGUMENTS
```

This will:
- Create epic issue on GitHub
- Create sub-issues (using parallel agents if appropriate)
- Rename task files to issue IDs
- Create worktree

### 4. Output

```
🚀 Epic Oneshot Complete: $ARGUMENTS

Step 1: Decomposition ✓
  - Tasks created: {count}

Step 2: GitHub Sync ✓
  - Epic: #{number}
  - Sub-issues created: {count}
  - Worktree: ../epic-$ARGUMENTS

Ready for development!
  Start work: /ccpm:epic-start $ARGUMENTS
  Or single task: /ccpm:issue-start {task_number}
```

## Important Notes

This is simply a convenience wrapper that runs:
1. `/ccpm:epic-decompose`
2. `/ccpm:epic-sync`

Both commands handle their own error checking, parallel execution, and validation. This command just orchestrates them in sequence.

Use this when you're confident the epic is ready and want to go from epic to GitHub issues in one step.
