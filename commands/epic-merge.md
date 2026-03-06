---
allowed-tools: Bash, Read, Write
---

# Epic Merge

Merge completed epic from worktree back to main branch.

## Usage
```
/ccpm:epic-merge <epic_name>
```

## Quick Check

1. **Verify worktree exists:**
   ```bash
   git worktree list | grep "epic-$ARGUMENTS" || echo "❌ No worktree for epic: $ARGUMENTS"
   ```

2. **Check for active agents:**
   Read `.pm/epics/$ARGUMENTS/execution-status.md`
   If active agents exist: "⚠️ Active agents detected. Stop them first with: /ccpm:epic-stop $ARGUMENTS"

## Instructions

### 1. Pre-Merge Validation

Navigate to worktree and check status:
```bash
cd ../epic-$ARGUMENTS
git status --porcelain
```

If there are uncommitted changes, warn: "Uncommitted changes in worktree. Commit or stash changes before merging."

Then fetch and check branch status:
```bash
git fetch origin
git status -sb
```

### 2. Run Tests (Optional but Recommended)

```bash
# Look for test commands based on project type
if [ -f package.json ]; then
  npm test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f pom.xml ]; then
  mvn test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  ./gradlew test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f composer.json ]; then
  ./vendor/bin/phpunit || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f *.sln ] || [ -f *.csproj ]; then
  dotnet test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f Cargo.toml ]; then
  cargo test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f go.mod ]; then
  go test ./... || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f Gemfile ]; then
  bundle exec rspec || bundle exec rake test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f pubspec.yaml ]; then
  flutter test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f Package.swift ]; then
  swift test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f CMakeLists.txt ]; then
  cd build && ctest || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f Makefile ]; then
  make test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
fi
```

### 3. Update Epic Documentation

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update `.pm/epics/$ARGUMENTS/epic.md`:
- Set status to "completed"
- Update completion date
- Add final summary

### 4. Attempt Merge

```bash
# Return to main repository
cd {main-repo-path}

# Ensure main is up to date
git checkout main
git pull origin main
```

Before merging, build the commit message:
1. Use the Glob tool to find all task files matching `.pm/epics/$ARGUMENTS/[0-9]*.md`
2. Use the Read tool to extract the `name:` field from each task file's frontmatter to build the feature list
3. Use the Read tool to read `.pm/epics/$ARGUMENTS/epic.md` and extract the `github:` field to get the epic issue number

Then perform the merge:
```bash
git merge epic/$ARGUMENTS --no-ff -m "Merge epic: $ARGUMENTS

Completed features:
{feature_list built from task names}

{If epic issue number found: Closes epic #{epic_issue}}"
```

### 5. Handle Merge Conflicts

If merge fails with conflicts:
```bash
git status
git diff --name-only --diff-filter=U
```

Report the conflicted files and present options:
```
❌ Merge conflicts detected!

Conflicts in:
{list of conflicted files from git diff output}

Options:
1. Resolve manually:
   - Edit conflicted files
   - git add {files}
   - git commit

2. Abort merge:
   git merge --abort

3. Get help:
   /ccpm:epic-resolve $ARGUMENTS

Worktree preserved at: ../epic-$ARGUMENTS
```

### 6. Post-Merge Cleanup

If merge succeeds:
```bash
# Push to remote
git push origin main

# Clean up worktree
git worktree remove ../epic-$ARGUMENTS
echo "✅ Worktree removed: ../epic-$ARGUMENTS"

# Delete branch
git branch -d epic/$ARGUMENTS
git push origin --delete epic/$ARGUMENTS 2>/dev/null || true

# Archive epic locally
mkdir -p .pm/epics/archived/
mv .pm/epics/$ARGUMENTS .pm/epics/archived/
echo "✅ Epic archived: .pm/epics/archived/$ARGUMENTS"
```

Before archiving, use the Glob tool to find all task files matching `.pm/epics/$ARGUMENTS/[0-9]*.md` and use the Edit tool to change `status: open` to `status: closed` in each task file's frontmatter.

### 7. Update GitHub Issues

Close related issues:

1. Use the Read tool to read `.pm/epics/archived/$ARGUMENTS/epic.md` and extract the `github:` field to get the epic issue number.
2. Close the epic issue:
   ```bash
   gh issue close $epic_issue -c "Epic completed and merged to main"
   ```
3. Use the Glob tool to find all task files matching `.pm/epics/archived/$ARGUMENTS/[0-9]*.md`.
4. For each task file, use the Read tool to extract the `github:` field and get the issue number.
5. Close each task issue:
   ```bash
   gh issue close $issue_num -c "Completed in epic merge"
   ```

### 8. Final Output

```
✅ Epic Merged Successfully: $ARGUMENTS

Summary:
  Branch: epic/$ARGUMENTS → main
  Commits merged: {count}
  Files changed: {count}
  Issues closed: {count}

Cleanup completed:
  ✓ Worktree removed
  ✓ Branch deleted
  ✓ Epic archived
  ✓ GitHub issues closed

Next steps:
  - Deploy changes if needed
  - Start new epic: /ccpm:prd-new {feature}
  - View completed work: git log --oneline -20
```

## Conflict Resolution Help

If conflicts need resolution:
```
The epic branch has conflicts with main.

This typically happens when:
- Main has changed since epic started
- Multiple epics modified same files
- Dependencies were updated

To resolve:
1. Open conflicted files
2. Look for <<<<<<< markers
3. Choose correct version or combine
4. Remove conflict markers
5. git add {resolved files}
6. git commit
7. git push

Or abort and try later:
  git merge --abort
```

## Important Notes

- Always check for uncommitted changes first
- Run tests before merging when possible
- Use --no-ff to preserve epic history
- Archive epic data instead of deleting
- Close GitHub issues to maintain sync
