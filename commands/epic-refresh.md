---
allowed-tools: Read, Write, LS
---

# Epic Refresh

Update epic progress based on task states.

## Usage
```
/ccpm:epic-refresh <epic_name>
```

## Instructions

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`) by finding `.pm/initiatives/*/$ARGUMENTS/epic.md`.

### 1. Count Task Status

Scan all task files in `{epic_dir}/`:
- Count total tasks
- Count tasks with `status: closed`
- Count tasks with `status: open`
- Count tasks with work in progress

### 2. Calculate Progress

```
progress = (closed_tasks / total_tasks) * 100
```

Round to nearest integer.

### 3. Determine Epic Status

- If progress = 0% and no work started: `backlog`
- If progress > 0% and < 100%: `in-progress`
- If progress = 100%: `completed`

### 4. Update Epic

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Use the Edit tool to update epic.md frontmatter:
```yaml
status: {calculated_status}
progress: {calculated_progress}%
updated: {current_datetime}
```

### 5. Output

```
🔄 Epic refreshed: $ARGUMENTS

Tasks:
  Closed: {closed_count}
  Open: {open_count}
  Total: {total_count}

Progress: {old_progress}% → {new_progress}%
Status: {old_status} → {new_status}

{If complete}: Run /ccpm:epic-close $ARGUMENTS to close epic
{If in progress}: Run /ccpm:next to see priority tasks
```

## Important Notes

This is useful after manual task edits.
Don't modify task files, only epic status.
Preserve all other frontmatter fields.
