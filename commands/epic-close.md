---
allowed-tools: Bash, Read, Write, LS
---

# Epic Close

Mark an epic as complete when all tasks are done.

## Usage
```
/ccpm:epic-close <epic_name>
```

## Instructions

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`) by finding `.pm/initiatives/*/$ARGUMENTS/epic.md`.

### 1. Verify All Tasks Complete

Check all task files in `{epic_dir}/`:
- Verify all have `status: closed` in frontmatter
- If any open tasks found: "❌ Cannot close epic. Open tasks remain: {list}"

### 2. Update Epic Status

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update epic.md frontmatter:
```yaml
status: completed
progress: 100%
updated: {current_datetime}
completed: {current_datetime}
```

### 3. Update Initiative Status

If epic references an Initiative, update its status to "complete".

### 4. Satisfaction Rating

Before closing, ask the user to rate their satisfaction:
- "Rate your satisfaction with this epic's outcome (1-5, or 'skip'):"
- If user provides a rating (1-5), save it:
  ```bash
  source scripts/pm/stats-satisfaction.sh && stats_save_rating epic $ARGUMENTS immediate {rating}
  ```
- If user says 'skip', proceed without saving

### 5. Archive Option

Ask user: "Archive completed epic? (yes/no)"

If yes:
- Move epic directory to `.pm/.archived/{epic_name}/`
- Create archive summary with completion date

### 6. Output

```
✅ Epic closed: $ARGUMENTS
  Tasks completed: {count}
  Duration: {days_from_created_to_completed}

{If archived}: Archived to .pm/.archived/

Next epic: Run /ccpm:next to see priority work
```

## Important Notes

Only close epics with all tasks complete.
Preserve all data when archiving.
Update related Initiative status.
