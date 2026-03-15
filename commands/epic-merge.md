---
allowed-tools: Bash, Read, Write
---

# Epic Merge

Merge completed epic branch back to its parent branch (initiative branch or main).

## Usage
```
/ccpm:epic-merge <epic_name>
```

## Quick Check

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`) by finding `.pm/initiatives/*/$ARGUMENTS/epic.md`.

### Determine Merge Target
Run:
```bash
git branch -a | grep "initiative/" | head -1 | sed 's/^[* ]*//' | sed 's|remotes/origin/||'
```
If this produces output, use that value as `MERGE_TARGET` (new two-level model). Otherwise, use `main` (backward compat).

1. **Verify worktree or branch exists:**
   ```bash
   git worktree list | grep "epic-$ARGUMENTS" || git branch -a | grep "epic/$ARGUMENTS" || echo "❌ No worktree/branch for epic: $ARGUMENTS"
   ```

2. **Check for active agents:**
   Read `{epic_dir}/execution-status.md`
   If active agents exist: "⚠️ Active agents detected. Stop them first with: /ccpm:epic-stop $ARGUMENTS"

## Instructions

### 1. Pre-Merge Validation

Check status in the epic worktree or branch:
```bash
# If worktree exists, check status there; otherwise checkout the branch
if git worktree list | grep -q "epic-$ARGUMENTS"; then
  git -C ../epic-$ARGUMENTS status --porcelain
else
  git checkout epic/$ARGUMENTS
  git status --porcelain
fi
```

If there are uncommitted changes, warn: "Uncommitted changes detected. Commit or stash changes before merging."

Then fetch and check branch status:
```bash
git fetch origin 2>/dev/null || true
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

Update `{epic_dir}/epic.md`:
- Set status to "completed"
- Update completion date
- Add final summary

### 4. Attempt Merge

```bash
# Ensure merge target is up to date
git checkout $MERGE_TARGET
git pull origin $MERGE_TARGET 2>/dev/null || true
```

Before merging, build the commit message:
1. Use the Glob tool to find all task files matching `{epic_dir}/[0-9]*.md`
2. Use the Read tool to extract the `name:` field from each task file's frontmatter to build the feature list
Then perform the merge:
```bash
git merge epic/$ARGUMENTS --no-ff -m "Merge epic: $ARGUMENTS

Completed features:
{feature_list built from task names}"
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

Worktree preserved at: ../epic-$ARGUMENTS (if applicable)
```

### 6. Post-Merge Cleanup

Before archiving, use the Glob tool to find all task files matching `{epic_dir}/[0-9]*.md` and use the Edit tool to change `status: open` to `status: closed` in each task file's frontmatter.

If merge succeeds:
```bash
# Push merge target to remote (only if merging to main)
if [ "$MERGE_TARGET" = "main" ]; then
  git push origin main
fi

# Clean up worktree if it exists
if git worktree list | grep -q "epic-$ARGUMENTS"; then
  git worktree remove ../epic-$ARGUMENTS
  echo "✅ Worktree removed: ../epic-$ARGUMENTS"
fi

# Delete epic branch
git branch -d epic/$ARGUMENTS
git push origin --delete epic/$ARGUMENTS 2>/dev/null || true

# Archive epic within initiative directory
# Determine the initiative directory (the parent of `{epic_dir}`)
mkdir -p "{initiative_dir}/archived/"
mv "{epic_dir}" "{initiative_dir}/archived/"
echo "✅ Epic archived within initiative directory"
```

### 7. Final Output

```
✅ Epic Merged Successfully: $ARGUMENTS

Summary:
  Branch: epic/$ARGUMENTS → $MERGE_TARGET
  Commits merged: {count}
  Files changed: {count}

Cleanup completed:
  ✓ Worktree removed (if applicable)
  ✓ Branch deleted
  ✓ Epic archived

Next steps:
  - If merging to initiative branch: start next epic or run /ccpm:initiative-merge {initiative}
  - If merging to main: deploy changes if needed
  - View completed work: git log --oneline -20
```

## Conflict Resolution Help

If conflicts need resolution:
```
The epic branch has conflicts with the merge target.

This typically happens when:
- The parent branch has changed since epic started
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
- When merging to an initiative branch, do NOT push to remote or delete the initiative branch — that's `initiative-merge`'s job
