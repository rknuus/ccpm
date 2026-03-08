---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Go

Decompose epic into tasks and start working — no GitHub sync required.

## Usage
```
/ccpm:epic-go <epic_name>
```

## Instructions

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open epic $ARGUMENTS epic-go || true`

### Phase 1: Decompose

Follow the same logic as `/ccpm:epic-decompose $ARGUMENTS`:

1. **Validate epic exists:**
   ```bash
   test -f .pm/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found. Run: /ccpm:prd-parse $ARGUMENTS"
   ```

2. **Check for existing tasks:**
   - If numbered task files exist in `.pm/epics/$ARGUMENTS/`, list them and ask: "⚠️ Found {count} existing tasks. Delete and recreate? (yes/no)"
   - Only proceed with explicit 'yes'

3. **Create task files** — Read the epic, decompose into tasks, create files in `.pm/epics/$ARGUMENTS/{id}.md` following the format and naming conventions from `epic-decompose` (use `.pm/next-id`, get real datetime via `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh`, use Task agents for parallel creation when appropriate).

4. **Update epic** with task summary section.

If decompose fails, stop with: "❌ Decompose failed. Task files may be partially created — review `.pm/epics/$ARGUMENTS/`"

### Phase 2: Start

Follow the same logic as `/ccpm:epic-start $ARGUMENTS` with these modifications:

- **Skip GitHub sync check** — do not require `github:` field in epic frontmatter
- **Skip GitHub issue status checks** — use local task frontmatter (`status`, `depends_on`, `parallel`) only
- **Branch push is optional:**
  ```bash
  git push -u origin epic/$ARGUMENTS 2>/dev/null || echo "ℹ️ No remote configured — continuing with local branch only"
  ```

Steps:
1. **Create or enter branch** per `/rules/branch-operations.md` (check for uncommitted changes, create/checkout `epic/$ARGUMENTS`, push with optional fallback above)
2. **Identify ready issues** from local task frontmatter — categorize as Ready / Blocked / In Progress / Complete
3. **Analyze and launch agents** for ready issues using Task tool, following `/rules/agent-coordination.md`
4. **Track active agents** in `.pm/epics/$ARGUMENTS/execution-status.md`
5. **Evidence-Based Demo** — after agents complete, walk through acceptance criteria per `epic-start` step 8

If start fails after decompose succeeded, bail out with:
"❌ Start failed. Task files from decompose are intact in `.pm/epics/$ARGUMENTS/`. Fix the issue and run: /ccpm:epic-start $ARGUMENTS"

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

## Output

```
Epic Go Complete: $ARGUMENTS

Phase 1: Decompose ✓
  - Tasks created: {count}
  - Parallel: {parallel_count} | Sequential: {sequential_count}

Phase 2: Start ✓
  - Branch: epic/$ARGUMENTS
  - Agents launched: {agent_count} across {issue_count} issues
  - Blocked issues: {blocked_count}

Monitor with: /ccpm:epic-status $ARGUMENTS
```

## Important Notes

This is a convenience wrapper that runs decompose + start without GitHub.
Use when you want to go from epic to working agents in one step, purely locally.
