# Standard Patterns for Commands

This file defines common patterns that all commands should follow to maintain consistency and simplicity.

## Core Principles

1. **Fail Fast** - Check critical prerequisites, then proceed
2. **Trust the System** - Don't over-validate things that rarely fail
3. **Clear Errors** - When something fails, say exactly what and how to fix it
4. **Minimal Output** - Show what matters, skip decoration

## Standard Validations

### Minimal Preflight
Only check what's absolutely necessary:
```markdown
## Quick Check
1. If command needs specific directory/file:
   - Use the Glob tool to check it exists
   - If missing, tell user exact command to fix it
2. If command needs GitHub:
   - Assume `gh` is authenticated (it usually is)
   - Only check on actual failure
```

### DateTime Handling

Follow the pattern in `/rules/datetime.md`: run the datetime command in Bash, read the output, and use it when writing files via Edit or Write tools. Never use `$()` command substitution to capture timestamps.

### Error Messages
Keep them short and actionable:
```markdown
{What failed}: {Exact solution}
Example: "Epic not found: Run /ccpm:initiative-parse feature-name"
```

## Standard Output Formats

### Success Output
```markdown
Done: {Action} complete
  - {Key result 1}
  - {Key result 2}
Next: {Single suggested action}
```

### List Output
```markdown
{Count} {items} found:
- {item 1}: {key detail}
- {item 2}: {key detail}
```

### Progress Output
```markdown
{Action}... {current}/{total}
```

## File Operations

Prefer Claude Code built-in tools over shell commands for file I/O:

| Task | Tool to use | Instead of |
|------|-------------|------------|
| Read a file | **Read** tool | `cat`, `head`, `tail` |
| Search file contents | **Grep** tool | `grep`, `rg` |
| Find files by name | **Glob** tool | `find`, `ls` |
| Edit a file in place | **Edit** tool | `sed`, `awk` |
| Create / overwrite a file | **Write** tool | `echo >`, `cat <<EOF >` |
| Create directories | Bash `mkdir -p` | (no built-in equivalent) |

Using built-in tools avoids shell approval prompts and is preferred for all file operations.

## GitHub Operations

### Trust gh CLI
```markdown
# Don't pre-check auth, just try the operation
gh {command} || echo "GitHub CLI failed. Run: gh auth login"
```

### Simple Issue Operations
```markdown
# Get what you need in one call
gh issue view {number} --json state,title,body
```

## Common Patterns to Avoid

### DON'T: Over-validate
```markdown
# Bad - too many checks
1. Check directory exists
2. Check permissions
3. Check git status
4. Check GitHub auth
5. Check rate limits
6. Validate every field
```

### DO: Check essentials
```markdown
# Good - just what's needed
1. Check target exists
2. Try the operation
3. Handle failure clearly
```

### DON'T: Verbose output
```markdown
# Bad - too much information
Starting operation...
Validating prerequisites...
Step 1 complete
Step 2 complete
Statistics: ...
Tips: ...
```

### DO: Concise output
```markdown
# Good - just results
Done: 3 files created
Failed: auth.test.js (syntax error - line 42)
```

### DON'T: Use command substitution for file operations
```markdown
# Bad - triggers approval prompts
CONTENT=$(cat file.md)
CURRENT_DATE=$(date -u ...)
RESULT=$(sed '...' file.md)
```

### DO: Use built-in tools and standalone commands
```markdown
# Good - no approval prompts
- Read tool to read file contents
- Edit tool to modify files
- Run `date -u ...` standalone in Bash, then use the printed value
```

## Quick Reference

### Git Commits

To avoid the `$(cat <<'EOF'...)` heredoc pattern that triggers complex approval prompts:

1. Use the **Write** tool to write the commit message to a temp file (e.g., `/tmp/commit-msg.txt`)
2. Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt [files...]`

This replaces `git add <files> && git commit -m "$(cat <<'EOF'...EOF)"` with a single, clean script call.

### Essential Tools Only
- Read/List operations: `Read`, `Glob`
- Content search: `Grep`
- File modification: `Edit`, `Write`
- GitHub operations: `Bash` (for `gh` CLI)
- Timestamps: `Bash` (standalone `date` command)
- Git commits: `Write` + `Bash` (via `ccpm-git-commit.sh`)

### Status Indicators
- Success (use sparingly)
- Error (always with solution)
- Warning (only if action needed)
- No emoji for normal output

### Exit Strategies
- Success: Brief confirmation
- Failure: Clear error + exact fix
- Partial: Show what worked, what didn't

## Remember

**Simple is not simplistic** - We still handle errors properly, we just don't try to prevent every possible edge case. We trust that:
- The file system usually works
- GitHub CLI is usually authenticated
- Git repositories are usually valid
- Users know what they're doing

Focus on the happy path, fail gracefully when things go wrong.
