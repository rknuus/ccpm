# Frontmatter Operations Rule

Standard patterns for working with YAML frontmatter in markdown files.

## Reading Frontmatter

Use the **Read** tool to read the markdown file, then parse the YAML between the `---` markers at the start of the file. If frontmatter is invalid or missing, use sensible defaults.

## Updating Frontmatter

Use the **Edit** tool to update frontmatter fields in place:
1. Preserve all existing fields
2. Only update specified fields
3. Always update `updated` field with current datetime (see `/rules/datetime.md`)

**Do not** use shell commands (`sed`, `awk`) to modify frontmatter -- the Edit tool handles in-place replacements safely without approval prompts.

## Standard Fields

### All Files
```yaml
---
name: {identifier}
created: {ISO datetime}      # Never change after creation
updated: {ISO datetime}      # Update on any modification
---
```

### Status Values
- Initiatives: `backlog`, `in-progress`, `complete`
- Epics: `backlog`, `in-progress`, `completed`
- Tasks: `open`, `in-progress`, `closed`

### Progress Tracking
```yaml
progress: {0-100}%           # For epics
completion: {0-100}%         # For progress files
```

## Creating New Files

Use the **Write** tool to create new markdown files with frontmatter:
```yaml
---
name: {from_arguments_or_context}
status: {initial_status}
created: {current_datetime}
updated: {current_datetime}
---
```

Get `{current_datetime}` by running the datetime command as described in `/rules/datetime.md`.

## Important Notes

- Never modify `created` field after initial creation
- Always use real datetime from system (see `/rules/datetime.md`)
- Validate frontmatter exists before trying to parse
- Use consistent field names across all files
