---
allowed-tools: Bash, Read, Write, LS
---

# Issue Reopen

Reopen a closed issue.

## Usage
```
/ccpm:issue-reopen <issue_number> [reason]
```

## Instructions

### 1. Find Local Task File

Use the Glob tool to check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists.
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update task file frontmatter:
```yaml
status: open
updated: {current_datetime}
```

### 3. Reset Progress

If progress file exists:
- Keep original started date
- Reset completion to previous value or 0%
- Add note about reopening with reason

### 4. Update Epic Progress

Recalculate epic progress with this task now open again.

### 5. Output

```
🔄 Reopened issue #$ARGUMENTS
  Reason: {reason_if_provided}
  Epic progress: {updated_progress}%

Start work with: /ccpm:issue-start $ARGUMENTS
```

## Important Notes

Preserve work history in progress files.
Don't delete previous progress, just reset status.
