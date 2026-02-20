---
allowed-tools: Read, Write, LS
---

**IMPORTANT:** Before proceeding, verify CCPM is initialized by checking if `.claude/rules/path-standards.md` exists. If it does not exist, stop immediately and tell the user: "CCPM not initialized. Run: /ccpm:init"

# Epic Edit

Edit epic details after creation.

## Usage
```
/ccpm:epic-edit <epic_name>
```

### Context Tracking
Run: `source scripts/pm/context-lib.sh && stats_context_open epic $ARGUMENTS epic-edit || true`

## Instructions

### 1. Read Current Epic

Read `.pm/epics/$ARGUMENTS/epic.md`:
- Parse frontmatter
- Read content sections

### 2. Interactive Edit

Ask user what to edit:
- Name/Title
- Description/Overview
- Architecture decisions
- Technical approach
- Dependencies
- Success criteria

### 3. Update Epic File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic.md:
- Preserve all frontmatter except `updated`
- Apply user's edits to content
- Update `updated` field with current datetime

### 4. Option to Update GitHub

If epic has GitHub URL in frontmatter:
Ask: "Update GitHub issue? (yes/no)"

If yes:
```bash
gh issue edit {issue_number} --body-file .pm/epics/$ARGUMENTS/epic.md
```

### Close Context
Run: `source scripts/pm/context-lib.sh && stats_context_close || true`

### 5. Output

```
✅ Updated epic: $ARGUMENTS
  Changes made to: {sections_edited}

{If GitHub updated}: GitHub issue updated ✅

View epic: /ccpm:epic-show $ARGUMENTS
```

## Important Notes

Preserve frontmatter history (created, github URL, etc.).
Don't change task files when editing epic.
Follow `/rules/frontmatter-operations.md`.
