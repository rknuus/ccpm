# Branch Operations

Git branches enable parallel development by allowing multiple developers to work on the same repository with isolated changes.

## Initiative-Level Branching

For initiatives with multiple epics, CCPM uses a two-level branch model:

```
main → initiative/{name} → epic/{epic-name}
```

### Branch Hierarchy

| Level | Branch | Created by | Merges into |
|-------|--------|------------|-------------|
| Initiative | `initiative/{name}` | `initiative-decompose` or `initiative-go` | `main` (via `initiative-merge`) |
| Epic | `epic/{epic-name}` | `epic-start` (from initiative branch) | `initiative/{name}` (via `epic-merge`) |

### Full Flow Example

```bash
# 1. Create initiative branch from main
git checkout main && git pull origin main
git checkout -b initiative/user-auth
git push -u origin initiative/user-auth

# 2. Create epic branches from the initiative branch
git checkout initiative/user-auth
git checkout -b epic/login-flow
git push -u origin epic/login-flow

# 3. Work on the epic, then merge back to initiative
git checkout initiative/user-auth
git merge epic/login-flow
git branch -d epic/login-flow

# 4. Repeat for other epics...
git checkout initiative/user-auth
git checkout -b epic/oauth-providers
# ... work ... merge back to initiative/user-auth ...

# 5. When all epics are done, merge initiative to main
git checkout main
git merge initiative/user-auth
git branch -d initiative/user-auth
```

### Key Rules

- Epic branches are created **from the initiative branch**, not from main
- `epic-merge` merges into the **initiative branch**
- `initiative-merge` merges the initiative branch into **main**
- Cross-epic coordination is safe: different epics use different branches

## Epic-Level Branching (Simple Workflow)

For standalone epics without a parent initiative, use the simpler single-level model below.

## Creating Branches

Always create branches from a clean main branch:
```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create branch for epic
git checkout -b epic/{name}
git push -u origin epic/{name}
```

The branch will be created and pushed to origin with upstream tracking.

## Working in Branches

### Agent Commits
- Agents commit directly to the branch
- Use small, focused commits
- Commit message format: `Issue #{number}: {description}`
- Example: `Issue #1234: Add user authentication schema`
- To commit: use the **Write** tool to write the commit message to `/tmp/commit-msg.txt`, then run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt {files...}`
- This avoids the `$(cat <<'EOF'...)` heredoc pattern that triggers complex approval prompts

### File Operations
```bash
# View branch status
git status
git log --oneline -5
```

For committing, use the commit script (see Agent Commits above) instead of raw `git add` + `git commit -m "$(cat <<...)"`.


## Parallel Work in Same Branch

Multiple agents can work in the same branch if they coordinate file access:
```bash
# Agent A works on API — write message via Write tool, then:
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/api/*

# Agent B works on UI (coordinate to avoid conflicts!)
git pull origin epic/{name}  # Get latest changes
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-git-commit.sh /tmp/commit-msg.txt src/ui/*
```

## Merging Branches

When epic is complete, merge back to main:
```bash
# From main repository
git checkout main
git pull origin main

# Merge epic branch
git merge epic/{name}

# If successful, clean up
git branch -d epic/{name}
git push origin --delete epic/{name}
```

## Handling Conflicts

If merge conflicts occur:
```bash
# Conflicts will be shown
git status

# Human resolves conflicts
# Then continue merge
git add {resolved-files}
git commit
```

## Branch Management

### List Active Branches
```bash
git branch -a
```

### Remove Stale Branch
```bash
# Delete local branch
git branch -d epic/{name}

# Delete remote branch
git push origin --delete epic/{name}
```

### Check Branch Status
```bash
# Current branch info
git branch -v

# Compare with main
git log --oneline main..epic/{name}
```

## Best Practices

1. **One branch per epic** - Not per issue
2. **Clean before create** - Always start from updated main
3. **Commit frequently** - Small commits are easier to merge
4. **Pull before push** - Get latest changes to avoid conflicts
5. **Use descriptive branches** - `epic/feature-name` not `feature`

## Common Issues

### Branch Already Exists
```bash
# Delete old branch first
git branch -D epic/{name}
git push origin --delete epic/{name}
# Then create new one
```

### Cannot Push Branch
```bash
# Check if branch exists remotely
git ls-remote origin epic/{name}

# Push with upstream
git push -u origin epic/{name}
```

### Merge Conflicts During Pull
```bash
# Stash changes if needed
git stash

# Pull and rebase
git pull --rebase origin epic/{name}

# Restore changes
git stash pop
```
