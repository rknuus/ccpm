# DateTime Rule

## Getting Current Date and Time

When any command requires the current date/time (for frontmatter, timestamps, or logs), you MUST obtain the REAL current date/time from the system rather than estimating or using placeholder values.

### How to Get Current DateTime

Run one of the following as a standalone Bash command and read its output:

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Or use the utility script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh
```

**Do NOT capture the output with command substitution** (e.g., `CURRENT_DATE=$(...)`) -- instead, run the command, read the printed value, and use it directly when writing frontmatter via the Edit or Write tool.

### Required Format

All dates MUST use ISO 8601 format with UTC timezone:
- Format: `YYYY-MM-DDTHH:MM:SSZ`
- Example: `2024-01-15T14:30:45Z`

### Workflow

1. Run the datetime command above in Bash.
2. Read the printed timestamp from the output.
3. Use the Read tool to read the target file.
4. Use the Edit tool (or Write tool for new files) to insert the timestamp value into the frontmatter.

For files being **created**: set both `created` and `updated` to the timestamp.
For files being **updated**: only change `updated`; preserve the original `created` value.

### Important Notes

- **Never use placeholder dates** like `[Current ISO date/time]` or `YYYY-MM-DD`
- **Never estimate dates** -- always get the actual system time
- **Always use UTC** (the `Z` suffix) for consistency across timezones

## Rule Priority

This rule has **HIGHEST PRIORITY** and must be followed by all commands that:
- Create new files with frontmatter
- Update existing files with frontmatter
- Track timestamps or progress
- Log any time-based information
