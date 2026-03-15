---
allowed-tools: Read, Write, LS
---

# Issue Edit

Edit issue details locally.

## Usage
```
/ccpm:issue-edit <issue_number>
```

## Instructions

### 1. Find Local Task File

Use the Glob tool to check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists.
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Interactive Edit

Ask user what to edit:
- Title
- Description/Body
- Acceptance criteria
- Priority/Size

### 3. Update Local File

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update task file with changes:
- Update frontmatter `name` if title changed
- Update body content if description changed
- Update `updated` field with current datetime

### 4. Output

```
✅ Updated issue #$ARGUMENTS
  Changes:
    {list_of_changes_made}
```

## Important Notes

Preserve frontmatter fields not being edited.
Follow `/rules/frontmatter-operations.md`.
