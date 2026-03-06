# Agent Coordination

Rules for multiple agents working in parallel within the same epic worktree.

## Parallel Execution Principles

1. **File-level parallelism** - Agents working on different files never conflict
2. **Explicit coordination** - When same file needed, coordinate explicitly
3. **Fail fast** - Surface conflicts immediately, don't try to be clever
4. **Human resolution** - Conflicts are resolved by humans, not agents

## Work Stream Assignment

Each agent is assigned a work stream from the issue analysis:
```yaml
# From {issue}-analysis.md
Stream A: Database Layer
  Files: src/db/*, migrations/*
  Agent: backend-specialist

Stream B: API Layer
  Files: src/api/*
  Agent: api-specialist
```

Agents should only modify files in their assigned patterns.

## File Access Coordination

### Check Before Modify
Before modifying a shared file:
```bash
# Check if file is being modified
git status {file}

# If modified by another agent, wait
if [[ $(git status --porcelain {file}) ]]; then
  echo "Waiting for {file} to be available..."
  sleep 30
  # Retry
fi
```

### Atomic Commits
Make commits atomic and focused. Use the **Write** tool to create `/tmp/commit-msg.txt`, then the commit script:
```bash
# Good - Single purpose commit
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/api/users.ts src/api/users.test.ts

# Bad - Mixed concerns (too many unrelated files)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/api/* src/db/* src/ui/*
```

This avoids the `$(cat <<'EOF'...)` heredoc pattern that triggers complex approval prompts.

## Communication Between Agents

### Through Commits
Agents see each other's work through commits:
```bash
# Agent checks what others have done
git log --oneline -10

# Agent pulls latest changes
git pull origin epic/{name}
```

### Through Progress Files
Each stream maintains progress:
```markdown
# .pm/epics/{epic}/updates/{issue}/stream-A.md
---
stream: Database Layer
agent: backend-specialist
started: {datetime}
status: in_progress
---

## Completed
- Created user table schema
- Added migration files

## Working On
- Adding indexes

## Blocked
- None
```

### Through Analysis Files
The analysis file is the contract:
```yaml
# Agents read this to understand boundaries
Stream A:
  Files: src/db/*  # Agent A only touches these
Stream B:
  Files: src/api/* # Agent B only touches these
```

## Handling Conflicts

### Conflict Detection
```bash
# If commit fails due to conflict
git commit -m "Issue #1234: Update"
# Error: conflicts exist

# Agent should report and wait
echo "❌ Conflict detected in {files}"
echo "Human intervention needed"
```

### Conflict Resolution
Always defer to humans:
1. Agent detects conflict
2. Agent reports issue
3. Agent pauses work
4. Human resolves
5. Agent continues

Never attempt automatic merge resolution.

## Synchronization Points

### Natural Sync Points
- After each commit
- Before starting new file
- When switching work streams
- Every 30 minutes of work

### Explicit Sync
```bash
# Pull latest changes
git pull --rebase origin epic/{name}

# If conflicts, stop and report
if [[ $? -ne 0 ]]; then
  echo "❌ Sync failed - human help needed"
  exit 1
fi
```

## Agent Communication Protocol

### Status Updates
Agents should update their status regularly. Use the **Write** tool to update progress files and create commit messages, then commit:
```bash
# Commit progress update
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt stream-A.md
```

### Coordination Requests
When agents need to coordinate:
```markdown
# In stream-A.md
## Coordination Needed
- Need to update src/types/index.ts
- Will modify after Stream B commits
- ETA: 10 minutes
```

## Parallel Commit Strategy

### No Conflicts Possible
When working on completely different files, agents can commit simultaneously using the commit script.

### Sequential When Needed
When touching shared resources:
```bash
# Agent A commits first (write message via Write tool, then:)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/types/index.ts

# Agent B waits, then proceeds (after A's commit)
git pull
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/api/users.ts
```

## Best Practices

1. **Commit early and often** - Smaller commits = fewer conflicts
2. **Stay in your lane** - Only modify assigned files
3. **Communicate changes** - Update progress files
4. **Pull frequently** - Stay synchronized with other agents
5. **Fail loudly** - Report issues immediately
6. **Never force** - No `--force` flags ever

## Common Patterns

### Starting Work
```bash
1. cd ../epic-{name}
2. git pull
3. Check {issue}-analysis.md for assignment
4. Update stream-{X}.md with "started"
5. Begin work on assigned files
```

### During Work
```bash
1. Make changes to assigned files
2. Commit with clear message
3. Update progress file
4. Check for new commits from others
5. Continue or coordinate as needed
```

### Completing Work
```bash
1. Final commit for stream
2. Update stream-{X}.md with "completed"
3. Check if other streams need help
4. Report completion
```
