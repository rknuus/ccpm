---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# Tech Context

## Language & Runtime

- **Primary language**: Bash (POSIX-compatible shell scripts)
- **Runtime**: macOS/Linux with standard Unix tools
- **No build system**: Scripts are directly executable

## Dependencies

- **jq**: JSON processing (used heavily in stats and context scripts)
- **gh**: GitHub CLI for issue/PR operations
- **git**: Version control, branch/worktree management
- **gh-sub-issue**: GitHub CLI extension for parent-child issue relationships (optional)
- **date**: System date for ISO 8601 timestamps
- **find/sed/awk**: Standard Unix text processing

## Claude Code Integration

- **Plugin system**: `.claude-plugin/plugin.json` defines the plugin identity
- **Commands/Skills**: Markdown files in `commands/` loaded as `/ccpm:*` namespace
- **Agents**: Markdown files in `agents/` define subagent prompts
- **Rules**: Markdown files in `.claude/rules/` auto-loaded into conversations
- **Hooks**: `UserPromptSubmit` and `SessionEnd` hooks for auto-context tracking

## Data Formats

- **Markdown with YAML frontmatter**: Initiatives, epics, tasks (`.pm/initiatives/*.md`, `.pm/epics/*/*.md`)
- **JSON**: Context state (`.pm/stats/active-context.json`), cached stats (`.pm/stats/*/stats.json`), settings (`.pm/ccpm-settings.json`)
- **JSONL**: Claude Code session logs (`~/.claude/projects/*/*.jsonl`) — read-only, parsed for stats

## Development Tools

- **Testing**: Custom bash test framework with `assert_eq`/`assert_contains` helpers
- **Linting**: ShellCheck (implied by `set -euo pipefail` usage)
- **CI**: None currently configured locally
