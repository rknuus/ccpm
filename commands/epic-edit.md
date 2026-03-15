---
allowed-tools: Read, Write, LS
---

# Epic Edit

Edit epic details after creation.

## Usage
```
/ccpm:epic-edit <epic_name>
```

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open epic $ARGUMENTS epic-edit || true`

## Instructions

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`):
1. Check `.pm/initiatives/*/$ARGUMENTS/epic.md` (new layout)
2. Fall back to `.pm/epics/$ARGUMENTS/epic.md` (old layout)
Use the first path found.

### 1. Read Current Epic

Read `{epic_dir}/epic.md`:
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

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update epic.md:
- Preserve all frontmatter except `updated`
- Apply user's edits to content
- Update `updated` field with current datetime

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 4. Output

```
✅ Updated epic: $ARGUMENTS
  Changes made to: {sections_edited}

View epic: /ccpm:epic-show $ARGUMENTS
```

## Important Notes

Preserve frontmatter history (created, etc.).
Don't change task files when editing epic.
Follow `/rules/frontmatter-operations.md`.
