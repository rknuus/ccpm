---
allowed-tools: Bash, Read, Write, LS
---

**IMPORTANT:** Before proceeding, verify CCPM is initialized by checking if `.claude/rules/path-standards.md` exists. If it does not exist, stop immediately and tell the user: "CCPM not initialized. Run: /ccpm:init"

# Issue Close

Mark an issue as complete and close it on GitHub.

## Usage
```
/ccpm:issue-close <issue_number> [completion_notes]
```

## Instructions

### 1. Find Local Task File

First check if `.pm/epics/*/$ARGUMENTS.md` exists (new naming).
If not found, search for task file with `github:.*issues/$ARGUMENTS` in frontmatter (old naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 3. Architect Review (Optional)

Find the epic name from the task file path and check if architect review is enabled:
```bash
epic_name={extracted_from_path}
architect_mode=$(grep '^architect:' .pm/epics/$epic_name/epic.md | sed 's/^architect: *//')
```

If `architect_mode` is `gate` or `advisory`:
- Run: `/ccpm:architect-review $epic_name --checkpoint code --task $ARGUMENTS`
- If gate mode and review returns "Needs Changes": report issues and do not close the issue
- If advisory mode: log findings and continue with closing

If `architect_mode` is empty or `off`: skip silently.

### 4. Update Progress File

If progress file exists at `.pm/epics/{epic}/updates/$ARGUMENTS/progress.md`:
- Set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime

### 5. Close on GitHub

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

### 6. Update Epic Task List on GitHub

Check the task checkbox in the epic issue:

```bash
# Get epic name from local task file path
epic_name={extract_from_path}

# Get epic issue number from epic.md
epic_issue=$(grep 'github:' .pm/epics/$epic_name/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  # Get current epic body
  gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md

  # Check off this task
  sed -i "s/- \[ \] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md

  # Update epic issue
  gh issue edit $epic_issue --body-file /tmp/epic-body.md

  echo "✓ Updated epic progress on GitHub"
fi
```

### 7. Update Epic Progress

- Count total tasks in epic
- Count closed tasks
- Calculate new progress percentage
- Update epic.md frontmatter progress field

### 8. Output

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
