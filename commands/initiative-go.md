---
allowed-tools: Bash, Read, Write, LS, Task
---

# Initiative Go

Parse Initiative into epic, decompose into tasks, and start agents — no GitHub sync required.

## Usage
```
/ccpm:initiative-go <feature_name>
```

## Instructions

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-go || true`

### Phase 1: Parse

Follow the same logic as `/ccpm:initiative-parse $ARGUMENTS`:

1. **Validate Initiative exists:**
   ```bash
   test -f .pm/initiatives/$ARGUMENTS.md || echo "❌ Initiative not found. Run: /ccpm:initiative-new $ARGUMENTS"
   ```

2. **Check for existing epic:**
   - Check `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md` first (new layout)
   - Fall back to `.pm/epics/$ARGUMENTS/epic.md` (old layout)
   - If found in either location, ask: "⚠️ Epic '$ARGUMENTS' already exists. Overwrite? (yes/no)"
   - Only proceed with explicit 'yes'

3. **Create initiative branch:**
   ```bash
   # Create initiative branch from main (or enter existing one)
   if ! git branch -a | grep -q "initiative/$ARGUMENTS"; then
     git checkout main
     git pull origin main 2>/dev/null || true
     git checkout -b initiative/$ARGUMENTS
     git push -u origin initiative/$ARGUMENTS 2>/dev/null || echo "ℹ️ No remote configured — continuing with local branch only"
     echo "✅ Created branch: initiative/$ARGUMENTS"
   else
     git checkout initiative/$ARGUMENTS
     echo "✅ Using existing branch: initiative/$ARGUMENTS"
   fi
   ```

4. **Create epic** — Read the Initiative, perform technical analysis, create `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md` following the format and guidelines from `initiative-parse`.

If parse fails, stop with: "❌ Parse failed. Check the Initiative at `.pm/initiatives/$ARGUMENTS.md`"

### Phase 2: Decompose

Follow the same logic as `/ccpm:epic-decompose $ARGUMENTS`:

1. **Check for existing tasks:**
   - If numbered task files exist in `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/`, list them and ask: "⚠️ Found {count} existing tasks. Delete and recreate? (yes/no)"
   - Only proceed with explicit 'yes'

2. **Create task files** — Read the epic, decompose into tasks, create files in `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/{id}.md` following the format and naming conventions from `epic-decompose` (use `.pm/next-id`, get real datetime via `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh`, use Task agents for parallel creation when appropriate).

3. **Update epic** with task summary section.

If decompose fails, stop with: "❌ Decompose failed. Task files may be partially created — review `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/`"

### Phase 3: Start

Follow the same logic as `/ccpm:epic-start $ARGUMENTS` with these modifications:

- **Skip GitHub sync check** — do not require `github:` field in epic frontmatter
- **Skip GitHub issue status checks** — use local task frontmatter (`status`, `depends_on`, `parallel`) only
- **Branch from initiative branch:**
  ```bash
  git checkout initiative/$ARGUMENTS
  git checkout -b epic/$ARGUMENTS
  git push -u origin epic/$ARGUMENTS 2>/dev/null || echo "ℹ️ No remote configured — continuing with local branch only"
  ```

Steps:
1. **Create or enter epic branch** from `initiative/$ARGUMENTS` (not from main). Check for uncommitted changes first.
2. **Identify ready issues** from local task frontmatter — categorize as Ready / Blocked / In Progress / Complete
3. **Analyze and launch agents** for ready issues using Task tool, following `/rules/agent-coordination.md`
4. **Track active agents** in `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/execution-status.md`
5. **Evidence-Based Demo** — after agents complete, walk through acceptance criteria per `epic-start` step 8

If start fails after earlier phases succeeded, bail out with:
"❌ Start failed. Epic and task files are intact in `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/`. Fix the issue and run: /ccpm:epic-start $ARGUMENTS"

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

## Output

```
Initiative Go Complete: $ARGUMENTS

Phase 1: Parse ✓
  - Branch: initiative/$ARGUMENTS
  - Epic created: .pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md

Phase 2: Decompose ✓
  - Tasks created: {count}
  - Parallel: {parallel_count} | Sequential: {sequential_count}

Phase 3: Start ✓
  - Epic branch: epic/$ARGUMENTS (from initiative/$ARGUMENTS)
  - Agents launched: {agent_count} across {issue_count} issues
  - Blocked issues: {blocked_count}

Monitor with: /ccpm:epic-status $ARGUMENTS
Merge epic when complete: /ccpm:epic-merge $ARGUMENTS
Merge initiative when all epics done: /ccpm:initiative-merge $ARGUMENTS
```

## Important Notes

This is a convenience wrapper that runs parse + decompose + start without GitHub.
Use when you want to go from Initiative to working agents in one step, purely locally.
Creates a single epic under the initiative — for multiple epics, use `/ccpm:initiative-decompose` instead.
