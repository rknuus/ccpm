# Claude Code PM

[![Automaze](https://img.shields.io/badge/By-automaze.io-4b3baf)](https://automaze.io)
&nbsp;
[![Claude Code](https://img.shields.io/badge/+-Claude%20Code-d97757)](https://github.com/automazeio/ccpm/blob/main/README.md)
[![GitHub Issues](https://img.shields.io/badge/+-GitHub%20Issues-1f2328)](https://github.com/automazeio/ccpm)
&nbsp;
[![Mentioned in Awesome Claude Code](https://awesome.re/mentioned-badge.svg)](https://github.com/hesreallyhim/awesome-claude-code?tab=readme-ov-file#general-)
&nbsp;
[![MIT License](https://img.shields.io/badge/License-MIT-28a745)](https://github.com/automazeio/ccpm/blob/main/LICENSE)
&nbsp;
[![Follow on 𝕏](https://img.shields.io/badge/𝕏-@aroussi-1c9bf0)](http://x.com/intent/follow?screen_name=aroussi)
&nbsp;
[![Star this repo](https://img.shields.io/github/stars/automazeio/ccpm.svg?style=social&label=Star%20this%20repo&maxAge=60)](https://github.com/automazeio/ccpm)

### Claude Code workflow to ship ~~faster~~ _better_ using spec-driven development, GitHub issues, Git worktrees, and multiple AI agents running in parallel.

**[中文文档 (Chinese Documentation)](zh-docs/README_ZH.md)**

Stop losing context. Stop blocking on tasks. Stop shipping bugs. This battle-tested system turns PRDs into epics, epics into GitHub issues, and issues into production code – with full traceability at every step.

![Claude Code PM](screenshot.webp)

## Table of Contents

- [Background](#background)
- [The Workflow](#the-workflow)
- [What Makes This Different?](#what-makes-this-different)
- [Why GitHub Issues?](#why-github-issues)
- [Core Principle: No Vibe Coding](#core-principle-no-vibe-coding)
- [System Architecture](#system-architecture)
- [Workflow Phases](#workflow-phases)
- [Command Reference](#command-reference)
- [The Parallel Execution System](#the-parallel-execution-system)
- [Key Features & Benefits](#key-features--benefits)
- [Proven Results](#proven-results)
- [Example Flow](#example-flow)
- [Get Started Now](#get-started-now)
- [Upgrading](#upgrading)
- [Local vs Remote](#local-vs-remote)
- [Technical Notes](#technical-notes)
- [Support This Project](#support-this-project)

## Background

Every team struggles with the same problems:
- **Context evaporates** between sessions, forcing constant re-discovery
- **Parallel work creates conflicts** when multiple developers touch the same code
- **Requirements drift** as verbal decisions override written specs
- **Progress becomes invisible** until the very end

This system solves all of that.

## The Workflow

```mermaid
graph LR
    A[PRD Creation] --> B[Epic Planning]
    B --> C[Task Decomposition]
    C --> D[GitHub Sync]
    D --> E[Parallel Execution]
```

### See It In Action (60 seconds)

```bash
# Create a comprehensive PRD through guided brainstorming
/ccpm:prd-new memory-system

# Transform PRD into a technical epic with task breakdown
/ccpm:prd-parse memory-system

# Push to GitHub and start parallel execution
/ccpm:epic-oneshot memory-system
/ccpm:issue-start 1235
```

> **Command namespace:** When installed as a plugin the namespace is `/ccpm:*` (e.g. `/ccpm:prd-new`).
> Legacy install-script installations use `/pm:*` (e.g. `/pm:prd-new`).

## What Makes This Different?

| Traditional Development | Claude Code PM System |
|------------------------|----------------------|
| Context lost between sessions | **Persistent context** across all work |
| Serial task execution | **Parallel agents** on independent tasks |
| "Vibe coding" from memory | **Spec-driven** with full traceability |
| Progress hidden in branches | **Transparent audit trail** in GitHub |
| Manual task coordination | **Intelligent prioritization** with `/pm:next` |

## Why GitHub Issues?

Most Claude Code workflows operate in isolation – a single developer working with AI in their local environment. This creates a fundamental problem: **AI-assisted development becomes a silo**.

By using GitHub Issues as our database, we unlock something powerful:

### 🤝 **True Team Collaboration**
- Multiple Claude instances can work on the same project simultaneously
- Human developers see AI progress in real-time through issue comments
- Team members can jump in anywhere – the context is always visible
- Managers get transparency without interrupting flow

### 🔄 **Seamless Human-AI Handoffs**
- AI can start a task, human can finish it (or vice versa)
- Progress updates are visible to everyone, not trapped in chat logs
- Code reviews happen naturally through PR comments
- No "what did the AI do?" meetings

### 📈 **Scalable Beyond Solo Work**
- Add team members without onboarding friction
- Multiple AI agents working in parallel on different issues
- Distributed teams stay synchronized automatically
- Works with existing GitHub workflows and tools

### 🎯 **Single Source of Truth**
- No separate databases or project management tools
- Issue state is the project state
- Comments are the audit trail
- Labels provide organization

This isn't just a project management system – it's a **collaboration protocol** that lets humans and AI agents work together at scale, using infrastructure your team already trusts.

## Core Principle: No Vibe Coding

> **Every line of code must trace back to a specification.**

We follow a strict 5-phase discipline:

1. **🧠 Brainstorm** - Think deeper than comfortable
2. **📝 Document** - Write specs that leave nothing to interpretation
3. **📐 Plan** - Architect with explicit technical decisions
4. **⚡ Execute** - Build exactly what was specified
5. **📊 Track** - Maintain transparent progress at every step

No shortcuts. No assumptions. No regrets.

## System Architecture

When installed as a **plugin** (recommended), CCPM lives at the repository root:

```
<project-root>/
├── .claude-plugin/
│   ├── plugin.json       # Plugin manifest (name, version, entry points)
│   └── marketplace.json  # Marketplace registry config
├── agents/               # Task-oriented agents (for context preservation)
├── commands/             # Command definitions (flat layout)
│   ├── prd-new.md        # /ccpm:prd-new
│   ├── epic-decompose.md # /ccpm:epic-decompose
│   ├── context-create.md # Context commands (prefixed)
│   ├── testing-run.md    # Testing commands (prefixed)
│   └── ...
├── hooks/                # Git hook helpers
├── scripts/              # Utility scripts
└── .pm/                  # PM workspace (gitignored)
    ├── epics/
    │   └── [epic-name]/  # Epic and related tasks
    │       ├── epic.md
    │       ├── [#].md    # Individual task files
    │       └── updates/  # Work-in-progress updates
    └── prds/             # PRD files
```

When installed via the **install script** (legacy), files are placed under `.claude/`:

```
.claude/
├── commands/
│   ├── pm/            # Project management commands
│   ├── context/       # Context commands
│   └── testing/       # Testing commands
├── ccpm/              # CCPM internals (agents, scripts, rules, etc.)
└── settings.local.json
```

> **Note:** The plugin layout uses a flat `commands/` directory with prefixed filenames
> (e.g. `context-create.md`, `testing-run.md`) instead of subdirectories.

## Workflow Phases

### 1. Product Planning Phase

```bash
/pm:prd-new feature-name
```
Launches comprehensive brainstorming to create a Product Requirements Document capturing vision, user stories, success criteria, and constraints.

**Output:** `.pm/prds/feature-name.md`

### 2. Implementation Planning Phase

```bash
/pm:prd-parse feature-name
```
Transforms PRD into a technical implementation plan with architectural decisions, technical approach, and dependency mapping.

**Output:** `.pm/epics/feature-name/epic.md`

### 3. Task Decomposition Phase

```bash
/pm:epic-decompose feature-name
```
Breaks epic into concrete, actionable tasks with acceptance criteria, effort estimates, and parallelization flags.

**Output:** `.pm/epics/feature-name/[task].md`

### 4. GitHub Synchronization

```bash
/pm:epic-sync feature-name
# Or for confident workflows:
/pm:epic-oneshot feature-name
```
Pushes epic and tasks to GitHub as issues with appropriate labels and relationships.

### 5. Execution Phase

```bash
/pm:issue-start 1234  # Launch specialized agent
/pm:issue-sync 1234   # Push progress updates
/pm:next             # Get next priority task
```
Specialized agents implement tasks while maintaining progress updates and an audit trail.

## Command Reference

> [!TIP]
> Type `/ccpm:help` (plugin) or `/pm:help` (legacy) for a concise command summary.
> Commands below use the `/pm:` prefix. Plugin users should substitute `/ccpm:` instead.

### Initial Setup
- `/pm:init` - Install dependencies and configure GitHub

### PRD Commands
- `/pm:prd-new` - Launch brainstorming for new product requirement
- `/pm:prd-parse` - Convert PRD to implementation epic
- `/pm:prd-list` - List all PRDs
- `/pm:prd-edit` - Edit existing PRD
- `/pm:prd-status` - Show PRD implementation status

### Epic Commands
- `/pm:epic-decompose` - Break epic into task files
- `/pm:epic-sync` - Push epic and tasks to GitHub
- `/pm:epic-oneshot` - Decompose and sync in one command
- `/pm:epic-list` - List all epics
- `/pm:epic-show` - Display epic and its tasks
- `/pm:epic-close` - Mark epic as complete
- `/pm:epic-edit` - Edit epic details
- `/pm:epic-refresh` - Update epic progress from tasks

### Issue Commands
- `/pm:issue-show` - Display issue and sub-issues
- `/pm:issue-status` - Check issue status
- `/pm:issue-start` - Begin work with specialized agent
- `/pm:issue-sync` - Push updates to GitHub
- `/pm:issue-close` - Mark issue as complete
- `/pm:issue-reopen` - Reopen closed issue
- `/pm:issue-edit` - Edit issue details

### Workflow Commands
- `/pm:next` - Show next priority issue with epic context
- `/pm:status` - Overall project dashboard
- `/pm:standup` - Daily standup report
- `/pm:blocked` - Show blocked tasks
- `/pm:in-progress` - List work in progress

### Sync Commands
- `/pm:sync` - Full bidirectional sync with GitHub
- `/pm:import` - Import existing GitHub issues

### Maintenance Commands
- `/pm:validate` - Check system integrity
- `/pm:clean` - Archive completed work
- `/pm:search` - Search across all content

## The Parallel Execution System

### Issues Aren't Atomic

Traditional thinking: One issue = One developer = One task

**Reality: One issue = Multiple parallel work streams**

A single "Implement user authentication" issue isn't one task. It's...

- **Agent 1**: Database tables and migrations
- **Agent 2**: Service layer and business logic
- **Agent 3**: API endpoints and middleware
- **Agent 4**: UI components and forms
- **Agent 5**: Test suites and documentation

All running **simultaneously** in the same worktree.

### The Math of Velocity

**Traditional Approach:**
- Epic with 3 issues
- Sequential execution

**This System:**
- Same epic with 3 issues
- Each issue splits into ~4 parallel streams
- **12 agents working simultaneously**

We're not assigning agents to issues. We're **leveraging multiple agents** to ship faster.

### Context Optimization

**Traditional single-thread approach:**
- Main conversation carries ALL the implementation details
- Context window fills with database schemas, API code, UI components
- Eventually hits context limits and loses coherence

**Parallel agent approach:**
- Main thread stays clean and strategic
- Each agent handles its own context in isolation
- Implementation details never pollute the main conversation
- Main thread maintains oversight without drowning in code

Your main conversation becomes the conductor, not the orchestra.

### GitHub vs Local: Perfect Separation

**What GitHub Sees:**
- Clean, simple issues
- Progress updates
- Completion status

**What Actually Happens Locally:**
- Issue #1234 explodes into 5 parallel agents
- Agents coordinate through Git commits
- Complex orchestration hidden from view

GitHub doesn't need to know HOW the work got done – just that it IS done.

### The Command Flow

```bash
# Analyze what can be parallelized
/pm:issue-analyze 1234

# Launch the swarm
/pm:epic-start memory-system

# Watch the magic
# 12 agents working across 3 issues
# All in: ../epic-memory-system/

# One clean merge when done
/pm:epic-merge memory-system
```

## Key Features & Benefits

### 🧠 **Context Preservation**
Never lose project state again. Each epic maintains its own context, agents read from `.claude/context/`, and updates locally before syncing.

### ⚡ **Parallel Execution**
Ship faster with multiple agents working simultaneously. Tasks marked `parallel: true` enable conflict-free concurrent development.

### 🔗 **GitHub Native**
Works with tools your team already uses. Issues are the source of truth, comments provide history, and there is no dependency on the Projects API.

### 🤖 **Agent Specialization**
Right tool for every job. Different agents for UI, API, and database work. Each reads requirements and posts updates automatically.

### 📊 **Full Traceability**
Every decision is documented. PRD → Epic → Task → Issue → Code → Commit. Complete audit trail from idea to production.

### 🚀 **Developer Productivity**
Focus on building, not managing. Intelligent prioritization, automatic context loading, and incremental sync when ready.

## Proven Results

Teams using this system report:
- **89% less time** lost to context switching – you'll use `/compact` and `/clear` a LOT less
- **5-8 parallel tasks** vs 1 previously – editing/testing multiple files at the same time
- **75% reduction** in bug rates – due to the breaking down features into detailed tasks
- **Up to 3x faster** feature delivery – based on feature size and complexity

## Example Flow

```bash
# Start a new feature
/pm:prd-new memory-system

# Review and refine the PRD...

# Create implementation plan
/pm:prd-parse memory-system

# Review the epic...

# Break into tasks and push to GitHub
/pm:epic-oneshot memory-system
# Creates issues: #1234 (epic), #1235, #1236 (tasks)

# Start development on a task
/pm:issue-start 1235
# Agent begins work, maintains local progress

# Sync progress to GitHub
/pm:issue-sync 1235
# Updates posted as issue comments

# Check overall status
/pm:epic-show memory-system
```

## Get Started Now

### Option A: Plugin Install (Recommended)

1. **Add the CCPM marketplace and install the plugin** in Claude Code:

   ```
   /plugin marketplace add rknuus/ccpm
   /plugin install ccpm@ccpm-marketplace
   ```

2. **Initialize the PM system**:
   ```bash
   /ccpm:init
   ```
   This command will:
   - Install GitHub CLI (if needed)
   - Authenticate with GitHub
   - Install [gh-sub-issue extension](https://github.com/yahsan2/gh-sub-issue) for proper parent-child relationships
   - Create required directories
   - Update .gitignore

3. **Start your first feature**:
   ```bash
   /ccpm:prd-new your-feature-name
   ```

### Option B: Install Script (Fallback)

Use the install script if plugin installation is not available or if you need to install into a third-party project.

1. **Install into your project**:

   #### Unix/Linux/macOS

   ```bash
   cd path/to/your/project/
   curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash
   ```

   #### Windows (cmd)
   ```cmd
   curl -o ccpm.bat https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh && ccpm.bat
   ```

   #### Third-Party Projects

   When installing into a project you do not own, use `--third-party` mode.
   This writes exclusions to `.git/info/exclude` instead of `.gitignore`,
   keeping the host project's tracked files unchanged:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash -s -- --third-party
   ```

   See all options (`--version`, `--third-party`, `--help`) in the [installation guide](install/README.md).

2. **Initialize the PM system**:
   ```bash
   /pm:init
   ```

3. **Create `CLAUDE.md`** with your repository information:
   ```bash
   /init include rules from .claude/CLAUDE.md
   ```
   > If you already have a `CLAUDE.md` file, run `/re-init` to update it with important rules from `.claude/CLAUDE.md`.

4. **Prime the system**:
   ```bash
   /context:create
   ```

5. **Start your first feature**:
   ```bash
   /pm:prd-new your-feature-name
   ```

Watch as structured planning transforms into shipped code.

## Upgrading

### From Install Script to Plugin

If you previously installed CCPM via `curl | bash`, follow these steps to migrate to the plugin system:

1. **Install the plugin** (your existing `.pm/` data is preserved automatically):
   ```
   /plugin marketplace add rknuus/ccpm
   /plugin install ccpm@ccpm-marketplace
   ```

2. **Remove the old installation** once you have confirmed the plugin works:
   ```bash
   rm -rf .claude/ccpm .claude/commands
   ```

3. **Update your command usage** -- the namespace changes from `/pm:*` to `/ccpm:*`:
   - `/pm:prd-new` becomes `/ccpm:prd-new`
   - `/pm:epic-oneshot` becomes `/ccpm:epic-oneshot`
   - `/pm:issue-start` becomes `/ccpm:issue-start`
   - (all other commands follow the same pattern)

Your `.pm/` directory (PRDs, epics, task files) remains untouched during migration.

### Plugin Updates

To update to the latest version of the plugin:

```
/plugin update ccpm
```

### Install Script Upgrades

If using the install script, re-run it to upgrade. The script detects the
current version (stored in `.claude/ccpm/.version`) and offers to upgrade,
skip, or overwrite.

```bash
curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash
```

To pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash -s -- --version v1.0.0
```

## Local vs Remote

| Operation | Local | GitHub |
|-----------|-------|--------|
| PRD Creation | ✅ | — |
| Implementation Planning | ✅ | — |
| Task Breakdown | ✅ | ✅ (sync) |
| Execution | ✅ | — |
| Status Updates | ✅ | ✅ (sync) |
| Final Deliverables | — | ✅ |

## Technical Notes

### GitHub Integration
- Uses **gh-sub-issue extension** for proper parent-child relationships
- Falls back to task lists if extension not installed
- Epic issues track sub-task completion automatically
- Labels provide additional organization (`epic:feature`, `task:feature`)

### File Naming Convention
- Tasks start as `001.md`, `002.md` during decomposition
- After GitHub sync, renamed to `{issue-id}.md` (e.g., `1234.md`)
- Makes it easy to navigate: issue #1234 = file `1234.md`

### Design Decisions
- Intentionally avoids GitHub Projects API complexity
- All commands operate on local files first for speed
- Synchronization with GitHub is explicit and controlled
- Worktrees provide clean git isolation for parallel work
- GitHub Projects can be added separately for visualization

---

## Support This Project

Claude Code PM was developed at [Automaze](https://automaze.io) **for developers who ship, by developers who ship**.

If Claude Code PM helps your team ship better software:

- ⭐ **[Star this repository](https://github.com/automazeio/ccpm)** to show your support
- 🐦 **[Follow @aroussi on X](https://x.com/aroussi)** for updates and tips


---

> [!TIP]
> **Ship faster with Automaze.** We partner with founders to bring their vision to life, scale their business, and optimize for success.
> **[Visit Automaze to book a call with me ›](https://automaze.io)**

---

## Star History

![Star History Chart](https://api.star-history.com/svg?repos=automazeio/ccpm)
