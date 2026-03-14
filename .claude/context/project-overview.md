---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-08T16:33:11Z
version: 1.0
author: Claude Code PM System
---

# Project Overview

## Features

### Initiative Management
- `/ccpm:initiative-new` — Guided brainstorming to create Initiative documents
- `/ccpm:initiative-parse` — Convert Initiative to technical implementation epic
- `/ccpm:initiative-go` — Parse, decompose, and start agents in one step (local-only, no GitHub sync)
- `/ccpm:initiative-list`, `/ccpm:initiative-edit`, `/ccpm:initiative-status` — CRUD operations

### Epic Management
- `/ccpm:epic-decompose` — Break epic into concrete, actionable tasks
- `/ccpm:epic-sync` — Push epic and tasks to GitHub as issues
- `/ccpm:epic-oneshot` — Decompose + sync in one command
- `/ccpm:epic-start` — Launch parallel agents to work on tasks
- `/ccpm:epic-merge` — Merge completed epic branch to main
- `/ccpm:epic-show`, `/ccpm:epic-list`, `/ccpm:epic-close`, `/ccpm:epic-edit`

### Issue Execution
- `/ccpm:issue-start` — Begin work with specialized agent
- `/ccpm:issue-sync` — Push progress updates to GitHub
- `/ccpm:issue-close`, `/ccpm:issue-reopen`, `/ccpm:issue-edit`

### Workflow & Status
- `/ccpm:next` — Show next priority issue with epic context
- `/ccpm:status` — Overall project dashboard
- `/ccpm:standup` — Daily standup report
- `/ccpm:blocked`, `/ccpm:in-progress` — Filtered views

### Stats & Analytics
- `/ccpm:stats` — Token usage, working/waiting time overview across all work items
- `/ccpm:stats-show` — Detailed stats for a specific item
- `/ccpm:stats-rate` — Rate satisfaction with a completed item

### Context Management
- `/ccpm:context-create` — Generate baseline project context documentation
- `/ccpm:context-update` — Refresh context with recent changes
- `/ccpm:context-prime` — Load context in new sessions

### Testing & Maintenance
- `/ccpm:testing-prime`, `/ccpm:testing-run` — Test management
- `/ccpm:validate` — Check system integrity
- `/ccpm:clean` — Archive completed work

## Integration Points

- **GitHub Issues**: Bidirectional sync via `gh` CLI
- **Git branches/worktrees**: Epic-level isolation for parallel work
- **Claude Code plugin system**: Installed via `/plugin install`
- **gh-sub-issue extension**: Parent-child issue relationships
