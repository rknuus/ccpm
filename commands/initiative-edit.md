---
allowed-tools: Read, Write, LS
---

# Initiative Edit

Edit an existing Initiative document.

## Usage
```
/ccpm:initiative-edit <feature_name>
```

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-edit || true`

## Instructions

### 1. Read Current Initiative

Read `.pm/initiatives/$ARGUMENTS.md`:
- Parse frontmatter
- Read all sections

### 2. Interactive Edit

Ask user what sections to edit:
- Executive Summary
- Problem Statement
- User Stories
- Requirements (Functional/Non-Functional)
- Success Criteria
- Constraints & Assumptions
- Out of Scope
- Dependencies

### 3. Update Initiative

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update Initiative file:
- Preserve frontmatter except `updated` field
- Apply user's edits to selected sections
- Update `updated` field with current datetime

### 4. Check Epic Impact

If Initiative has associated epic:
- Notify user: "This Initiative has epic: {epic_name}"
- Ask: "Epic may need updating based on Initiative changes. Review epic? (yes/no)"
- If yes, show: "Review with: /ccpm:epic-edit {epic_name}"

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 5. Output

```
✅ Updated Initiative: $ARGUMENTS
  Sections edited: {list_of_sections}

{If has epic}: ⚠️ Epic may need review: {epic_name}

Next: /ccpm:initiative-decompose $ARGUMENTS to update epic
```

## Important Notes

Preserve original creation date.
Keep version history in frontmatter if needed.
Follow `/rules/frontmatter-operations.md`.
