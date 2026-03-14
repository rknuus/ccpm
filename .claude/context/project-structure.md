---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# Project Structure

## Root Layout

```
ccpm-fork/
├── .claude/                   # Claude Code integration
│   ├── agents/                # Agent definitions (test-runner, etc.)
│   ├── context/               # Project context files (this directory)
│   ├── hooks/                 # (reserved for consumer hook scripts)
│   ├── rules/                 # Rules loaded by Claude Code
│   ├── scripts/pm/            # Shell scripts for quick commands
│   └── settings.local.json    # Local permissions (gitignored: no)
├── .claude-plugin/            # Plugin metadata
│   ├── plugin.json            # Plugin identity and version
│   └── marketplace.json       # Marketplace listing
├── agents/                    # Agent prompt definitions
│   ├── architect.md
│   ├── code-analyzer.md
│   ├── file-analyzer.md
│   ├── parallel-worker.md
│   └── test-runner.md
├── commands/                  # Skill/command definitions (~50 .md files)
│   ├── initiative-new.md, initiative-parse.md, ...
│   ├── epic-decompose.md, epic-start.md, epic-sync.md, ...
│   ├── issue-start.md, issue-sync.md, ...
│   ├── stats.md, stats-show.md, stats-rate.md
│   └── context-create.md, context-prime.md, context-update.md
├── scripts/pm/                # Runtime shell scripts
│   ├── ccpm-context           # Context tracking (open/close/reopen/history)
│   ├── stats.sh               # Stats overview/show commands
│   ├── stats-lib.sh           # Stats computation library
│   ├── stats-satisfaction.sh  # Rating system
│   ├── stats-prompts.sh       # Prompt extraction
│   ├── hook-auto-context.sh   # Auto-context hook for consumer projects
│   └── *.sh                   # Various utility scripts
├── tests/                     # Test suites
│   ├── fixtures/              # Test data (JSONL files)
│   ├── test-context-lib.sh    # Context tracking tests (39 assertions)
│   ├── test-stats.sh          # Stats command tests (47 assertions)
│   ├── test-stats-lib.sh      # Stats library tests (39 assertions)
│   └── test-stats-prompts.sh  # Prompt extraction tests
├── rules/                     # Additional rules (may overlap with .claude/rules/)
├── hooks/                     # Hook definitions for plugin system
├── doc/                       # Chinese documentation translations
├── .pm/                       # PM workspace (gitignored in consumer projects)
│   ├── initiatives/           # Initiative files and nested epics/tasks
│   │   ├── {name}.md          # Initiative document
│   │   └── {name}/            # Epic directories for this initiative
│   │       └── {epic-name}/   # Epic with tasks
│   │           ├── epic.md    # Epic document
│   │           └── {id}.md    # Task files
│   ├── epics/                 # Legacy epic directories (backward compat)
│   ├── stats/                 # Cached stats and active-context.json
│   └── next-id               # Global task ID counter
├── CLAUDE.md                  # Project instructions for Claude
├── README.md                  # Main documentation
├── COMMANDS.md                # Command reference
├── AGENTS.md                  # Agent documentation
└── LOCAL_MODE.md              # Local-only workflow guide
```

## Key Conventions

- **Commands**: Markdown files in `commands/` define Claude Code skills (the `/ccpm:*` namespace)
- **Scripts**: Bash scripts in `scripts/pm/` handle runtime logic (stats, context tracking, init)
- **Tests**: Bash test scripts in `tests/` using `assert_eq`/`assert_contains` helpers
- **Agents**: Markdown files in `agents/` define specialized subagent prompts
- **Rules**: Markdown files in `.claude/rules/` and `rules/` are auto-loaded by Claude Code
