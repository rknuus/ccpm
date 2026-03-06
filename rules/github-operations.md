# GitHub Operations Rule

Standard patterns for GitHub CLI operations across all commands.

## CRITICAL: Repository Protection

**Before ANY GitHub operation that creates/modifies issues or PRs**, run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-repo-check.sh
```

If the script exits non-zero, **stop immediately** -- do not proceed with the GitHub operation.

This check MUST be performed in ALL commands that:
- Create issues (`gh issue create`)
- Edit issues (`gh issue edit`)
- Comment on issues (`gh issue comment`)
- Create PRs (`gh pr create`)
- Any other operation that modifies the GitHub repository

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
gh {command} || echo "GitHub CLI failed. Run: gh auth login"
```

## Common Operations

### Get Issue Details
```bash
gh issue view {number} --json state,title,labels,body
```

### Get Repository Name

Run these as standalone Bash commands (do NOT use `$()` substitution):

```bash
git remote get-url origin
```

Read the output, then extract the `owner/repo` portion to pass to `--repo`.

### Create Issue
```bash
gh issue create --repo "{owner/repo}" --title "{title}" --body-file {file} --label "{labels}"
```

### Update Issue
```bash
gh issue edit {number} --add-label "{label}" --add-assignee @me
```

### Add Comment
```bash
gh issue comment {number} --body-file {file}
```

## Error Handling

If any gh command fails:
1. Show clear error: "GitHub operation failed: {command}"
2. Suggest fix: "Run: gh auth login" or check issue number
3. Don't retry automatically

## Important Notes

- **ALWAYS** run the repo-check script before ANY write operation to GitHub
- Trust that gh CLI is installed and authenticated
- Use --json for structured output when parsing
- Keep operations atomic -- one gh command per action
- Don't check rate limits preemptively
