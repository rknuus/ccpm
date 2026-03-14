---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# System Patterns

## Architecture

CCPM is a **Claude Code plugin** that combines:
1. **Command definitions** (markdown) — describe what Claude should do when a skill is invoked
2. **Runtime scripts** (bash) — handle computation, I/O, and state management
3. **Agent definitions** (markdown) — specialized subagent prompts for parallel work

The plugin is stateless between sessions. All persistent state lives in `.pm/` (local workspace) and GitHub issues (remote sync).

## Key Patterns

### Command → Script Pattern
Commands (markdown skills) delegate heavy work to bash scripts:
- `commands/stats.md` → invokes `scripts/pm/stats.sh overview`
- `commands/epic-start.md` → invokes `scripts/pm/ccpm-context open/close`
- Commands handle user interaction; scripts handle computation

### Context Tracking
Every CCPM command wraps its work in `ccpm-context open/close`:
```bash
ccpm-context open <type> <name> <command>   # at start
# ... do work ...
ccpm-context close                          # at end
```
This creates time windows in `active-context.json` that stats uses to attribute JSONL session data to specific work items.

### Stats Pipeline
```
JSONL session files → stats_find_jsonl_files() → stats_filter_files_by_timerange()
  → stats_sum_tokens() / stats_derive_time() → cache in stats.json → display
```
- Tokens come from `message.usage` fields in JSONL entries
- Times come from gaps between consecutive user/assistant messages
- Idle gaps (>5min with no intermediate entries) are excluded
- Results are cached with version-based invalidation

### YAML Frontmatter Convention
All markdown files (Initiatives, epics, tasks) use YAML frontmatter for metadata:
```yaml
---
name: feature-name
status: open|in-progress|closed|completed
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---
```

### Error Handling
- Scripts use `set -euo pipefail` for strict error handling
- Optional function parameters use `${var:-default}` pattern
- Graceful degradation: `command || true` for non-critical operations
- Temp file pattern: write to `file.tmp`, then `mv file.tmp file`

### Testing Pattern
- Each test file is a standalone bash script
- Tests use `assert_eq "description" "expected" "actual"` helper
- Test isolation via `mktemp -d` with `trap 'rm -rf ...' EXIT`
- Environment variables override paths (`STATS_CONTEXT_FILE`, etc.)
- No external test framework dependency

### Path Resolution
- `scripts/pm/paths-lib.sh` provides centralized path resolution for `.pm/` directories
- Supports both new layout (`.pm/initiatives/{name}/{epic}/`) and legacy layout (`.pm/epics/{name}/`)
- All commands and scripts use path library functions instead of hardcoded paths

### Parallel Work Coordination
- One git branch per epic (not per task)
- For multi-epic initiatives: `main` → `initiative/{name}` → `epic/{epic-name}` (two-level model)
- For standalone epics: `main` → `epic/{name}` (simple model, backward compatible)
- Multiple agents work in the same branch on different files
- Agents coordinate through commits and progress files
- Conflicts are surfaced immediately for human resolution
