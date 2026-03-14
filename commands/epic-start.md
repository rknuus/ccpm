---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Start

Launch parallel agents to work on epic tasks in a shared branch.

## Usage
```
/ccpm:epic-start <epic_name>
```

## Quick Check

1. **Verify epic exists:**
   ```bash
   test -f .pm/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found. Run: /ccpm:initiative-parse $ARGUMENTS"
   ```

2. **Check GitHub sync:**
   Look for `github:` field in epic frontmatter.
   If missing: "❌ Epic not synced. Run: /ccpm:epic-sync $ARGUMENTS first"

3. **Check for branch:**
   ```bash
   git branch -a | grep "epic/$ARGUMENTS"
   ```

4. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If output is not empty: "❌ You have uncommitted changes. Please commit or stash them before starting an epic"

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open epic $ARGUMENTS epic-start || true`

## Instructions

### 1. Create or Enter Branch

Follow `/rules/branch-operations.md`:

Check for uncommitted changes first:
```bash
git status --porcelain
```
If there is output, stop with: "You have uncommitted changes. Please commit or stash them before starting an epic."

```bash
# If branch doesn't exist, create it
if ! git branch -a | grep -q "epic/$ARGUMENTS"; then
  git checkout main
  git pull origin main
  git checkout -b epic/$ARGUMENTS
  git push -u origin epic/$ARGUMENTS
  echo "✅ Created branch: epic/$ARGUMENTS"
else
  git checkout epic/$ARGUMENTS
  git pull origin epic/$ARGUMENTS
  echo "✅ Using existing branch: epic/$ARGUMENTS"
fi
```

### 2. Identify Ready Issues

Read all task files in `.pm/epics/$ARGUMENTS/`:
- Parse frontmatter for `status`, `depends_on`, `parallel` fields
- Check GitHub issue status if needed
- Build dependency graph

Categorize issues:
- **Ready**: No unmet dependencies, not started
- **Blocked**: Has unmet dependencies
- **In Progress**: Already being worked on
- **Complete**: Finished

### 3. Analyze Ready Issues

For each ready issue without analysis:
```bash
# Check for analysis
if ! test -f .pm/epics/$ARGUMENTS/{issue}-analysis.md; then
  echo "Analyzing issue #{issue}..."
  # Run analysis (inline or via Task tool)
fi
```

### 4. Launch Parallel Agents

For each ready issue with analysis:

```markdown
## Starting Issue #{issue}: {title}

Reading analysis...
Found {count} parallel streams:
  - Stream A: {description} (Agent-{id})
  - Stream B: {description} (Agent-{id})

Launching agents in branch: epic/$ARGUMENTS
```

Use Task tool to launch each stream:
```yaml
Task:
  description: "Issue #{issue} Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    Working in branch: epic/$ARGUMENTS
    Issue: #{issue} - {title}
    Stream: {stream_name}

    Your scope:
    - Files: {file_patterns}
    - Work: {stream_description}

    Read full requirements from:
    - .pm/epics/$ARGUMENTS/{task_file}
    - .pm/epics/$ARGUMENTS/{issue}-analysis.md

    Follow coordination rules in /rules/agent-coordination.md

    Commit frequently with message format:
    "Issue #{issue}: {specific change}"

    Update progress in:
    .pm/epics/$ARGUMENTS/updates/{issue}/stream-{X}.md
```

### 5. Track Active Agents

Create/update `.pm/epics/$ARGUMENTS/execution-status.md`:

```markdown
---
started: {datetime}
branch: epic/$ARGUMENTS
---

# Execution Status

## Active Agents
- Agent-1: Issue #1234 Stream A (Database) - Started {time}
- Agent-2: Issue #1234 Stream B (API) - Started {time}
- Agent-3: Issue #1235 Stream A (UI) - Started {time}

## Queued Issues
- Issue #1236 - Waiting for #1234
- Issue #1237 - Waiting for #1235

## Completed
- {None yet}
```

### 6. Monitor and Coordinate

Set up monitoring:
```bash
echo "
Agents launched successfully!

Monitor progress:
  /ccpm:epic-status $ARGUMENTS

View branch changes:
  git status

Stop all agents:
  /ccpm:epic-stop $ARGUMENTS

Merge when complete:
  /ccpm:epic-merge $ARGUMENTS
"
```

### 7. Handle Dependencies

As agents complete streams:
- Check if any blocked issues are now ready
- Launch new agents for newly-ready work
- Update execution-status.md

### 8. Evidence-Based Demo

After all agents complete, walk through each task's acceptance criteria with evidence.

**Gather evidence sources:**

1. Read each task file in `.pm/epics/$ARGUMENTS/*.md` and extract the `- [ ]` acceptance criteria
2. Map commits to tasks:
   ```bash
   git log --oneline main..HEAD | grep -oP 'Issue #\d+'
   ```
3. Run the project test suite live:
   ```bash
   # Detect and run test framework (same pattern as epic-merge)
   if [ -f package.json ]; then npm test
   elif [ -f pom.xml ]; then mvn test
   elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then ./gradlew test
   elif [ -f Makefile ]; then make test
   elif [ -f Cargo.toml ]; then cargo test
   elif [ -f go.mod ]; then go test ./...
   elif [ -f Gemfile ]; then bundle exec rspec || bundle exec rake test
   fi
   ```
   Capture the full output for reference during the walkthrough.

**For each task, walk through its acceptance criteria using this evidence hierarchy:**

1. **Live demo** — If the criterion describes observable CLI behavior, run the relevant command and show its output
2. **Test evidence** — Show relevant test results from the live test run that exercise this criterion
3. **Code diff** — Show `git diff main..HEAD -- <files>` for the task's commits and explain how the change satisfies the criterion

**Present results per task:**

```
## Task #N: <title>

### AC: <acceptance criterion text>
Evidence: <live demo | test | code diff>
<command output, test result, or diff explanation>
Result: Met | Gap

### AC: <next criterion>
...
```

**After all tasks, show a summary:**

```
Demo Summary: N/M acceptance criteria evidenced, K gaps found
```

**If gaps are found, warn but do not block:**

```
Gaps found — review above and request fixups if needed before merging.
```

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

## Output Format

```
🚀 Epic Execution Started: $ARGUMENTS

Branch: epic/$ARGUMENTS

Launching {total} agents across {issue_count} issues:

Issue #1234: Database Schema
  ├─ Stream A: Schema creation (Agent-1) ✓ Started
  └─ Stream B: Migrations (Agent-2) ✓ Started

Issue #1235: API Endpoints
  ├─ Stream A: User endpoints (Agent-3) ✓ Started
  ├─ Stream B: Post endpoints (Agent-4) ✓ Started
  └─ Stream C: Tests (Agent-5) ⏸ Waiting for A & B

Blocked Issues (2):
  - #1236: UI Components (depends on #1234)
  - #1237: Integration (depends on #1235, #1236)

Monitor with: /ccpm:epic-status $ARGUMENTS
```

## Error Handling

If agent launch fails:
```
❌ Failed to start Agent-{id}
  Issue: #{issue}
  Stream: {stream}
  Error: {reason}

Continue with other agents? (yes/no)
```

If uncommitted changes are found:
```
❌ You have uncommitted changes. Please commit or stash them before starting an epic.

To commit changes:
  git add .
  git commit -m "Your commit message"

To stash changes:
  git stash push -m "Work in progress"
  # (Later restore with: git stash pop)
```

If branch creation fails:
```
❌ Cannot create branch
  {git error message}

Try: git branch -d epic/$ARGUMENTS
Or: Check existing branches with: git branch -a
```

## Important Notes

- Follow `/rules/branch-operations.md` for git operations
- Follow `/rules/agent-coordination.md` for parallel work
- Agents work in the SAME branch (not separate branches)
- Maximum parallel agents should be reasonable (e.g., 5-10)
- Monitor system resources if launching many agents
