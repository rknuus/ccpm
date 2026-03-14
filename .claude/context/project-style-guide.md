---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# Project Style Guide

## Shell Scripts

### Header
```bash
#!/bin/bash
set -euo pipefail
```

### Variables
- `UPPER_CASE` for constants and environment variables
- `lower_case` for local variables
- Always quote variables: `"$var"` not `$var`
- Use `${var:-default}` for optional parameters (required by `set -u`)
- Use `local` for function-scoped variables

### Functions
- `snake_case` names with descriptive prefixes: `stats_sum_tokens()`, `cmd_overview()`
- Document with comments above the function
- Use `local` for all variables

### Error Handling
- `set -euo pipefail` at script top
- `command || true` for non-critical operations
- `trap 'cleanup' EXIT` for resource cleanup
- Temp files: write to `file.tmp`, then `mv file.tmp file`

### Output
- `echo "text"` for user-facing output
- `>&2` for error messages
- Minimal decoration — no emoji unless user requests it

## Test Scripts

### Structure
```bash
#!/bin/bash
set -euo pipefail
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  # ...
}

echo "=== Test Group Name ==="
assert_eq "description" "expected" "actual"

echo "Results: $passed passed, $failed failed"
```

### Conventions
- One test file per module/script
- Isolated via temp directories
- Environment variables to override paths
- No external test framework
- Print pass/fail summary at end

## Command Definitions (Markdown)

### Structure
- YAML frontmatter is NOT used in command files
- Start with `# Command Name`
- Include `## Usage`, `## Instructions`, `## Error Handling`
- Reference scripts via `${CLAUDE_PLUGIN_ROOT}/scripts/pm/`
- Context tracking: `ccpm-context open` at start, `ccpm-context close` at end

## Commit Messages

- Format: `Issue #N: Description` for task work
- Format: `fix: Description` or `feat: Description` for standalone changes
- Format: `Merge epic: epic-name` for merge commits
- Always include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` when AI-authored

## General Principles

- Follow existing patterns in the codebase
- Prefer editing existing files over creating new ones
- Cover new/changed code by tests
- Always lint code before committing
- Avoid code duplication
- Keep solutions minimal and focused
