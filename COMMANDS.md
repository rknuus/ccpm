# Commands

Complete reference of all commands available in the Claude Code PM system.

> **Note**: Project Management commands (`/ccpm:*`) are documented in the main [README.md](README.md#command-reference).
>
> **Epic Commands**: `/ccpm:epic-oneshot` (decompose + sync) is documented in the README.
> **Initiative Commands**: `/ccpm:initiative-go` (parse + decompose + start agents locally, no GitHub sync) is documented in the README.

## Table of Contents

- [Context Commands](#context-commands)
- [Testing Commands](#testing-commands)
- [Stats Commands](#stats-commands)
- [Utility Commands](#utility-commands)
- [Review Commands](#review-commands)

## Context Commands

Commands for managing project context in `.claude/context/`.

### `/ccpm:context-create`
- **Purpose**: Create initial project context documentation
- **Usage**: `/ccpm:context-create`
- **Description**: Analyzes the project structure and creates comprehensive baseline documentation in `.claude/context/`. Includes project overview, architecture, dependencies, and patterns.
- **When to use**: At project start or when context needs full rebuild
- **Output**: Multiple context files covering different aspects of the project

### `/ccpm:context-update`
- **Purpose**: Update existing context with recent changes
- **Usage**: `/ccpm:context-update`
- **Description**: Refreshes context documentation based on recent code changes, new features, or architectural updates. Preserves existing context while adding new information.
- **When to use**: After significant changes or before major work sessions
- **Output**: Updated context files with change tracking

### `/ccpm:context-prime`
- **Purpose**: Load context into current conversation
- **Usage**: `/ccpm:context-prime`
- **Description**: Reads all context files and loads them into the current conversation's memory. Essential for maintaining project awareness.
- **When to use**: At the start of any work session
- **Output**: Confirmation of loaded context

## Testing Commands

Commands for test configuration and execution.

### `/ccpm:testing-prime`
- **Purpose**: Configure testing setup
- **Usage**: `/ccpm:testing-prime`
- **Description**: Detects and configures the project's testing framework, creates testing configuration, and prepares the test-runner agent.
- **When to use**: Initial project setup or when testing framework changes
-  **Output**: `.claude/testing-config.md` with test commands and patterns

### `/ccpm:testing-run`
- **Purpose**: Execute tests with intelligent analysis
- **Usage**: `/ccpm:testing-run [test_target]`
- **Description**: Runs tests using the test-runner agent which captures output to logs and returns only essential results to preserve context.
- **Options**:
   - No arguments: Run all tests
   - File path: Run specific test file
   - Pattern: Run tests matching pattern
- **Output**: Test summary with failures analyzed, no verbose output in main thread

## Stats Commands

Commands for tracking project statistics and satisfaction ratings.

### `/ccpm:stats`
- **Purpose**: Display project statistics overview dashboard
- **Usage**: `/ccpm:stats`
- **Description**: Shows a high-level overview of project statistics including time spent, work item counts, and progress across Initiatives, epics, and tasks. Reads from `.pm/stats/` data files.
- **When to use**: To get a quick summary of project health and progress
- **Output**: Dashboard with aggregated statistics for all tracked work items

### `/ccpm:stats-show`
- **Purpose**: Show detailed statistics for a specific work item
- **Usage**: `/ccpm:stats-show <type> <name>`
- **Description**: Displays detailed statistics for a single work item including time tracking, token usage, satisfaction ratings, and prompt history. Type is `initiative`, `epic`, or `task`; name is the work item identifier.
- **When to use**: To drill down into metrics for a specific Initiative, epic, or task
- **Output**: Detailed statistics view for the specified work item

### `/ccpm:stats-rate`
- **Purpose**: Rate or re-rate satisfaction for a work item
- **Usage**: `/ccpm:stats-rate <type> <name>`
- **Description**: Collects a delayed satisfaction rating (1-5) for a completed work item. Shows any existing ratings, prompts for a new rating and optional note, then saves the result to `.pm/stats/`.
- **When to use**: After completing a work item, to record how satisfied you are with the outcome
- **Output**: Confirmation of saved rating with comparison to any existing ratings

## Utility Commands

General utility and maintenance commands.

### `/ccpm:config`
- **Purpose**: View or update CCPM project settings
- **Usage**: `/ccpm:config` or `/ccpm:config set <key> <value>`
- **Description**: Displays current CCPM settings or updates a specific setting. Settings are stored in `.pm/ccpm-settings.json`. Currently supports the `collectPrompts` setting (boolean) which controls whether user prompts are collected during stats computation.
- **When to use**: To check current settings or toggle prompt collection behavior
- **Output**: Current settings display, or confirmation of updated setting

### `/prompt`
- **Purpose**: Handle complex prompts with multiple references
- **Usage**: Write your prompt in the file, then type `/prompt`
- **Description**: Ephemeral command for when complex prompts with numerous @ references fail in direct input. The prompt is written to the command file first, then executed.
- **When to use**: When Claude's UI rejects complex prompts
- **Output**: Executes the written prompt

### `/re-init`
- **Purpose**: Update or create CLAUDE.md with PM rules
- **Usage**: `/re-init`
- **Description**: Updates the project's CLAUDE.md file with rules from `.claude/CLAUDE.md`, ensuring Claude instances have proper instructions.
- **When to use**: After cloning PM system or updating rules
- **Output**: Updated CLAUDE.md in project root

## Review Commands

Commands for handling external code review tools.

### `/code-rabbit`
- **Purpose**: Process CodeRabbit review comments intelligently
- **Usage**: `/code-rabbit` then paste comments
- **Description**: Evaluates CodeRabbit suggestions with context awareness, accepting valid improvements while ignoring context-unaware suggestions. Spawns parallel agents for multi-file reviews.
- **Features**:
   - Understands CodeRabbit lacks full context
   - Accepts: Real bugs, security issues, resource leaks
   - Ignores: Style preferences, irrelevant patterns
   - Parallel processing for multiple files
- **Output**: Summary of accepted/ignored suggestions with reasoning

## Command Patterns

All commands follow consistent patterns:

### Allowed Tools
Each command specifies its required tools in frontmatter:
- `Read, Write, LS` - File operations
- `Bash` - System commands
- `Task` - Sub-agent spawning
- `Grep` - Code searching

### Error Handling
Commands follow fail-fast principles:
- Check prerequisites first
- Clear error messages with solutions
- Never leave partial state

### Context Preservation
Commands that process lots of information:
- Use agents to shield main thread from verbose output
- Return summaries, not raw data
- Preserve only essential information

## Creating Custom Commands

To add new commands:

1. **Create file**: `commands/category/command-name.md`
2. **Add frontmatter**:
   ```yaml
   ---
   allowed-tools: Read, Write, LS
   ---
   ```
3. **Structure content**:
   - Purpose and usage
   - Preflight checks
   - Step-by-step instructions
   - Error handling
   - Output format

4. **Follow patterns**:
   - Keep it simple (no over-validation)
   - Fail fast with clear messages
   - Use agents for heavy processing
   - Return concise output

## Integration with Agents

Commands often use agents for heavy lifting:

- **test-runner**: Executes tests, analyzes results
- **file-analyzer**: Summarizes verbose files
- **code-analyzer**: Hunts bugs across codebase
- **parallel-worker**: Coordinates parallel execution

This keeps the main conversation context clean while doing complex work.

## Notes

- Commands are markdown files interpreted as instructions
- The `/` prefix triggers command execution
- Commands can spawn agents for context preservation
- All PM commands (`/ccpm:*`) are documented in the main README
- Commands follow rules defined in `/rules/`
