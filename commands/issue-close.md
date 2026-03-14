---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Mark an issue as complete and close it on GitHub.

## Usage
```
/ccpm:issue-close <issue_number> [completion_notes]
```

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open task $ARGUMENTS issue-close || true`

## Instructions

### 1. Find Local Task File

Use the Glob tool to check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists (new layout).
Fall back to `.pm/epics/*/$ARGUMENTS.md` (old layout).
If not found, use the Grep tool to search for `github:.*issues/$ARGUMENTS` in `.pm/initiatives/` and `.pm/epics/`.
If not found: "❌ No local task for issue #$ARGUMENTS"
Extract `{epic_dir}` from the found task file's parent directory.

### 2. Update Local Status

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Use the Edit tool to update the task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 3. Architect Review (Optional)

Extract the epic name from the task file path. Use the Read tool to read `{epic_dir}/epic.md` and extract the `architect:` field from frontmatter.

If `architect_mode` is `gate` or `advisory`:
- Run: `/ccpm:architect-review $epic_name --checkpoint code --task $ARGUMENTS`
- If gate mode and review returns "Needs Changes": report issues and do not close the issue
- If advisory mode: log findings and continue with closing

If `architect_mode` is empty or `off`: skip silently.

### 4. Update Progress File

If progress file exists at `{epic_dir}/updates/$ARGUMENTS/progress.md` (check with the Read tool):
- Use the Edit tool to set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime (from step 2)

### 5. Satisfaction Rating

Before closing, ask the user to rate their satisfaction:
- "Rate your satisfaction with this task's outcome (1-5, or 'skip'):"
- If user provides a rating (1-5), save it:
  ```bash
  source scripts/pm/stats-satisfaction.sh && stats_save_rating task $ARGUMENTS immediate {rating}
  ```
- If user says 'skip', proceed without saving

### 6. Close on GitHub

Add completion comment and close:
```bash
# Add final comment
echo "✅ Task completed

$ARGUMENTS

---
Closed at: {timestamp}" | gh issue comment $ARGUMENTS --body-file -

# Close the issue
gh issue close $ARGUMENTS
```

### 7. Update Epic Task List on GitHub

Extract the epic name from the local task file path. Use the Read tool to read `{epic_dir}/epic.md` and extract the GitHub issue number from the `github:` frontmatter field.

If an epic issue number is found:
```bash
# Get current epic body
gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
```

Use the Edit tool on `/tmp/epic-body.md` to check off this task by replacing `- [ ] #$ARGUMENTS` with `- [x] #$ARGUMENTS`.

Then update the epic issue:
```bash
gh issue edit $epic_issue --body-file /tmp/epic-body.md
```

### 8. Update Epic Progress

- Use the Glob tool to find all task files in the epic directory
- Use the Read tool to count total tasks and closed tasks (by checking `status:` in frontmatter)
- Calculate new progress percentage
- Use the Edit tool to update epic.md frontmatter progress field

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 9. Output

```
✅ Closed issue #$ARGUMENTS
  Local: Task marked complete
  GitHub: Issue closed & epic updated
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)

Next: Run /ccpm:next for next priority task
```

## Important Notes

Follow `/rules/frontmatter-operations.md` for updates.
Follow `/rules/github-operations.md` for GitHub commands.
Always sync local state before GitHub.
