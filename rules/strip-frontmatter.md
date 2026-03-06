# Strip Frontmatter

Standard approach for removing YAML frontmatter before sending content to GitHub.

## The Problem

YAML frontmatter contains internal metadata that should not appear in GitHub issues:
- status, created, updated fields
- Internal references and IDs
- Local file paths

## The Solution

Use the utility script to strip frontmatter from any markdown file:

```bash
# Output to stdout
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh input.md

# Output to a file
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh input.md /tmp/clean.md
```

The script removes the opening `---`, all YAML content, and the closing `---`. If the file has no frontmatter it passes content through unchanged.

## When to Strip Frontmatter

Always strip frontmatter when:
- Creating GitHub issues from markdown files
- Posting file content as comments
- Displaying content to external users
- Syncing to any external system

## Examples

### Creating an issue from a file
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh task.md /tmp/clean.md
gh issue create --body-file /tmp/clean.md --title "{title}" --label "{labels}"
```

### Posting a comment
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh progress.md /tmp/comment.md
gh issue comment 123 --body-file /tmp/comment.md
```

## Important Notes

- Keep original files intact -- only strip when sending to external systems
- The script handles files without frontmatter gracefully
