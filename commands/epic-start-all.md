---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Start All

Start all epics in an initiative sequentially — no user interaction until all epics are complete and ready for merging.

## Usage
```
/ccpm:epic-start-all <initiative_name>
```

## Preflight Checklist

Do not bother the user with preflight checks progress. Just do them and move on.

### Validation Steps

1. **Verify initiative exists:**
   - Check if `.pm/initiatives/$ARGUMENTS.md` exists
   - If not found: "❌ Initiative not found: $ARGUMENTS"

2. **Verify initiative branch exists:**
   ```bash
   git branch --list "initiative/$ARGUMENTS" | grep -q "initiative/$ARGUMENTS" || echo "❌ No initiative branch. Run: /ccpm:initiative-decompose $ARGUMENTS"
   ```

3. **Find all epics:**
   - Use Glob to find `.pm/initiatives/$ARGUMENTS/*/epic.md`
   - If no epics found: "❌ No epics found. Run: /ccpm:initiative-decompose $ARGUMENTS"

4. **Verify all epics have tasks:**
   - For each epic, check for numbered task files (`[0-9]*.md`) in the epic directory
   - If any epic has no tasks: "❌ Epic '{epic_name}' has no tasks. Run: /ccpm:epic-decompose {epic_name}"
   - List all epics missing tasks and stop

5. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If not empty: "❌ Uncommitted changes. Commit or stash before starting."

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS epic-start-all || true`

## Instructions

### 1. Build Epic Execution Order

Read each epic's frontmatter to extract the `depends_on` field.

Sort epics topologically:
- Epics with no dependencies come first
- Epics that depend on others come after their dependencies
- If circular dependencies detected: "❌ Circular epic dependency: {details}"

Report the planned order:
```
Execution plan for initiative: $ARGUMENTS

  1. {epic_name_1} (no dependencies)
  2. {epic_name_2} (depends on: epic_name_1)
  3. {epic_name_3} (depends on: epic_name_1)
  ...

Total: {count} epics, running sequentially.
Starting now — no interaction until all epics complete.
```

### 2. Execute Each Epic

For each epic in dependency order, perform the full epic-start → epic-merge cycle:

#### 2a. Start the Epic

Follow the same logic as `/ccpm:epic-start {epic_name}`:

1. **Create epic branch** from `initiative/$ARGUMENTS`:
   ```bash
   git checkout initiative/$ARGUMENTS
   git checkout -b epic/{epic_name}
   ```

2. **Identify ready tasks** from the epic's task files — parse frontmatter for `status`, `depends_on`, `parallel`

3. **Analyze and launch agents** for ready tasks using Task tool, following `/rules/agent-coordination.md`

4. **Wait for all agents to complete** — monitor task progress, launch blocked tasks as dependencies finish

5. **Evidence-Based Demo** — after all agents complete, walk through acceptance criteria with evidence (same as `epic-start` step 8)

#### 2b. Merge the Epic

After the epic completes, merge it back into the initiative branch:

1. **Update epic status** to "completed" in the epic's frontmatter
2. **Merge epic branch** into the initiative branch:
   ```bash
   git checkout initiative/$ARGUMENTS
   git merge epic/{epic_name} --no-ff -m "Merge epic: {epic_name}"
   ```
3. **Clean up** the epic branch:
   ```bash
   git branch -d epic/{epic_name}
   ```
4. **Report progress**:
   ```
   ✅ Epic {n}/{total} complete: {epic_name}
      Commits: {count} | Files changed: {count}
      Remaining: {remaining_count} epics
   ```

#### 2c. Handle Failures

If an epic fails (agent errors, merge conflicts, test failures):
```
❌ Epic '{epic_name}' failed: {reason}

Completed epics ({n}/{total}):
  ✅ {epic_1}
  ✅ {epic_2}
  ❌ {epic_name} (failed)
  ⏸ {epic_4} (not started)

The initiative branch contains all successfully merged epics.
To resume: fix the issue, then run /ccpm:epic-start {epic_name}
To merge what's done: /ccpm:initiative-merge $ARGUMENTS
```

Stop execution — do not continue to the next epic.

### 3. Run Tests

After all epics are merged into the initiative branch, run the project test suite:
```bash
git checkout initiative/$ARGUMENTS
if [ -f package.json ]; then npm test
elif [ -f Makefile ]; then make test
elif [ -f Cargo.toml ]; then cargo test
elif [ -f go.mod ]; then go test ./...
fi
```

Report test results.

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 4. Final Output

```
✅ All epics complete for initiative: $ARGUMENTS

Epics completed:
  ✅ {epic_1}: {task_count} tasks
  ✅ {epic_2}: {task_count} tasks
  ...

Summary:
  Total epics: {count}
  Total commits: {count}
  Total files changed: {count}
  Tests: {passed|failed|skipped}

All epic branches merged into: initiative/$ARGUMENTS
Ready to merge to main: /ccpm:initiative-merge $ARGUMENTS
```

## Important Notes

- Epics run **sequentially** in dependency order — each must complete before the next starts
- Each completed epic is **merged into the initiative branch** before the next starts, so dependent epics have access to prior work
- **No user interaction** during execution — runs autonomously until all epics complete or one fails
- On failure, stops immediately — completed epics remain merged in the initiative branch
- Follow `/rules/agent-coordination.md` for agent work within each epic
