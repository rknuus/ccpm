---
allowed-tools: Read, LS
---

# Epic Oneshot

Decompose epic into tasks in one operation. This is an alias for `/ccpm:epic-decompose`.

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
test -f {epic_dir}/epic.md || echo "❌ Epic not found. Run: /ccpm:initiative-decompose $ARGUMENTS"

# Check for existing tasks
if ls {epic_dir}/[0-9]*.md 2>/dev/null | grep -q .; then
  echo "⚠️ Tasks already exist. This will create duplicates."
  echo "Delete existing tasks or use /ccpm:epic-decompose to recreate."
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

### 3. Output

```
✅ Epic Oneshot Complete: $ARGUMENTS

Step 1: Decomposition ✓
  - Tasks created: {count}

Ready for development!
  Start work: /ccpm:epic-start $ARGUMENTS
  Or single task: /ccpm:issue-start {task_number}
```

## Important Notes

This is simply a convenience wrapper that runs `/ccpm:epic-decompose`.

The decompose command handles its own error checking, parallel execution, and validation. This command just orchestrates it.
