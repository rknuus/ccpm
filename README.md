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

> **Command namespace:** All commands use the `/ccpm:*` namespace (e.g. `/ccpm:prd-new`).

## What Makes This Different?

| Traditional Development | Claude Code PM System |
|------------------------|----------------------|
| Context lost between sessions | **Persistent context** across all work |
| Serial task execution | **Parallel agents** on independent tasks |
| "Vibe coding" from memory | **Spec-driven** with full traceability |
| Progress hidden in branches | **Transparent audit trail** in GitHub |
| Manual task coordination | **Intelligent prioritization** with `/ccpm:next` |

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

CCPM is installed as a Claude **plugin**. Commands create the directories they need on the fly. The full structure looks like this:

```
<your-project>/
├── .claude/
│   └── rules/            # CCPM rules (copied from the plugin)
└── .pm/                  # PM workspace (gitignored)
    ├── epics/
    │   └── [epic-name]/  # Epic and related tasks
    │       ├── epic.md
    │       ├── [#].md    # Individual task files
    │       └── updates/  # Work-in-progress updates
    └── prds/             # PRD files
```

The plugin itself (commands, agents, scripts) lives in its own repository and is loaded by Claude Code's plugin system.

## Workflow Phases

### 1. Product Planning Phase

```bash
/ccpm:prd-new feature-name
```
Launches comprehensive brainstorming to create a Product Requirements Document capturing vision, user stories, success criteria, and constraints.

**Output:** `.pm/prds/feature-name.md`

### 2. Implementation Planning Phase

```bash
/ccpm:prd-parse feature-name
```
Transforms PRD into a technical implementation plan with architectural decisions, technical approach, and dependency mapping.

**Output:** `.pm/epics/feature-name/epic.md`

### 3. Task Decomposition Phase

```bash
/ccpm:epic-decompose feature-name
```
Breaks epic into concrete, actionable tasks with acceptance criteria, effort estimates, and parallelization flags.

**Output:** `.pm/epics/feature-name/[task].md`

### 4. GitHub Synchronization

```bash
/ccpm:epic-sync feature-name
# Or for confident workflows:
/ccpm:epic-oneshot feature-name
```
Pushes epic and tasks to GitHub as issues with appropriate labels and relationships.

### 5. Execution Phase

```bash
/ccpm:issue-start 1234  # Launch specialized agent
/ccpm:issue-sync 1234   # Push progress updates
/ccpm:next             # Get next priority task
```
Specialized agents implement tasks while maintaining progress updates and an audit trail.

## Command Reference

> [!TIP]
> Type `/ccpm:help` for a concise command summary.

### Initial Setup (Optional)
- `/ccpm:init` - Set up GitHub labels, install `gh-sub-issue`, verify `gh` auth, and pre-create directories

### PRD Commands
- `/ccpm:prd-new` - Launch brainstorming for new product requirement
- `/ccpm:prd-parse` - Convert PRD to implementation epic
- `/ccpm:prd-list` - List all PRDs
- `/ccpm:prd-edit` - Edit existing PRD
- `/ccpm:prd-status` - Show PRD implementation status

### Epic Commands
- `/ccpm:epic-decompose` - Break epic into task files
- `/ccpm:epic-sync` - Push epic and tasks to GitHub
- `/ccpm:epic-oneshot` - Decompose and sync in one command
- `/ccpm:epic-list` - List all epics
- `/ccpm:epic-show` - Display epic and its tasks
- `/ccpm:epic-close` - Mark epic as complete
- `/ccpm:epic-edit` - Edit epic details
- `/ccpm:epic-refresh` - Update epic progress from tasks

### Issue Commands
- `/ccpm:issue-show` - Display issue and sub-issues
- `/ccpm:issue-status` - Check issue status
- `/ccpm:issue-start` - Begin work with specialized agent
- `/ccpm:issue-sync` - Push updates to GitHub
- `/ccpm:issue-close` - Mark issue as complete
- `/ccpm:issue-reopen` - Reopen closed issue
- `/ccpm:issue-edit` - Edit issue details

### Workflow Commands
- `/ccpm:next` - Show next priority issue with epic context
- `/ccpm:status` - Overall project dashboard
- `/ccpm:standup` - Daily standup report
- `/ccpm:blocked` - Show blocked tasks
- `/ccpm:in-progress` - List work in progress

### Sync Commands
- `/ccpm:sync` - Full bidirectional sync with GitHub
- `/ccpm:import` - Import existing GitHub issues

### Maintenance Commands
- `/ccpm:validate` - Check system integrity
- `/ccpm:clean` - Archive completed work
- `/ccpm:search` - Search across all content

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
/ccpm:issue-analyze 1234

# Launch the swarm
/ccpm:epic-start memory-system

# Watch the magic
# 12 agents working across 3 issues
# All in: ../epic-memory-system/

# One clean merge when done
/ccpm:epic-merge memory-system
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
/ccpm:prd-new memory-system

# Review and refine the PRD...

# Create implementation plan
/ccpm:prd-parse memory-system

# Review the epic...

# Break into tasks and push to GitHub
/ccpm:epic-oneshot memory-system
# Creates issues: #1234 (epic), #1235, #1236 (tasks)

# Start development on a task
/ccpm:issue-start 1235
# Agent begins work, maintains local progress

# Sync progress to GitHub
/ccpm:issue-sync 1235
# Updates posted as issue comments

# Check overall status
/ccpm:epic-show memory-system
```

## Get Started Now

1. **Add the CCPM marketplace and install the plugin** in Claude Code:

   ```
   /plugin marketplace add rknuus/ccpm
   /plugin install ccpm@ccpm-marketplace
   ```

   **Or test locally without installing** (e.g. to try a fork or a branch):

   ```bash
   # From your project directory, point to the local clone
   claude --plugin-dir /path/to/ccpm
   ```

   This loads the plugin for the current session only. Commands are available under the same `/ccpm:*` namespace.

2. **(Optional) Initialize the PM system** — recommended if you plan to sync with GitHub:
   ```bash
   /ccpm:init
   ```
   This sets up GitHub labels (`epic`, `task`), installs the [gh-sub-issue extension](https://github.com/yahsan2/gh-sub-issue), verifies `gh` authentication, and pre-creates the `.pm/` directory structure. You can skip this step — commands create the directories they need automatically.

3. **Start your first feature**:
   ```bash
   /ccpm:prd-new your-feature-name
   ```

## Upgrading

### Plugin Updates

To update to the latest version of the plugin:

```
/plugin update ccpm
```

### Migrating from Install Script

If you previously installed CCPM via the install script (`curl | bash`), follow these steps to migrate to the plugin system:

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
