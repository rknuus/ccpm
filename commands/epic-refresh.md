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
Determine the epic directory (`{epic_dir}`):
1. Check `.pm/initiatives/*/$ARGUMENTS/epic.md` (new layout)
2. Fall back to `{epic_dir}/epic.md` (old layout)
Use the first path found.

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

### 3. Update GitHub Task List

If epic has GitHub issue, sync task checkboxes:

Use the Read tool to read `{epic_dir}/epic.md` and extract the `github:` field to get the epic issue number.

If the epic has a GitHub issue:

1. Get the current epic body:
   ```bash
   gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
   ```

2. Use the Glob tool to find all task files matching `{epic_dir}/[0-9]*.md`.

3. For each task file, use the Read tool to extract the `github:` field (task issue number) and `status:` field.

4. Use the Edit tool on `/tmp/epic-body.md` to update checkboxes:
   - If task status is `closed`: replace `- [ ] #$task_issue` with `- [x] #$task_issue`
   - If task status is not `closed`: replace `- [x] #$task_issue` with `- [ ] #$task_issue`

5. Update the epic issue:
   ```bash
   gh issue edit $epic_issue --body-file /tmp/epic-body.md
   ```

### 4. Determine Epic Status

- If progress = 0% and no work started: `backlog`
- If progress > 0% and < 100%: `in-progress`
- If progress = 100%: `completed`

### 5. Update Epic

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Use the Edit tool to update epic.md frontmatter:
```yaml
status: {calculated_status}
progress: {calculated_progress}%
updated: {current_datetime}
```

### 6. Output

```
🔄 Epic refreshed: $ARGUMENTS

Tasks:
  Closed: {closed_count}
  Open: {open_count}
  Total: {total_count}

Progress: {old_progress}% → {new_progress}%
Status: {old_status} → {new_status}
GitHub: Task list updated ✓

{If complete}: Run /ccpm:epic-close $ARGUMENTS to close epic
{If in progress}: Run /ccpm:next to see priority tasks
```

## Important Notes

This is useful after manual task edits or GitHub sync.
Don't modify task files, only epic status.
Preserve all other frontmatter fields.
