---
allowed-tools: Bash, Read, Write
---

# Initiative Merge

Merge completed initiative from its branch back to main.

## Usage
```
/ccpm:initiative-merge <initiative_name>
```

## Preflight Checklist

Do not bother the user with preflight checks progress. Just do them and move on.

### Validation Steps

1. **Verify initiative exists:**
   - Check if `.pm/initiatives/$ARGUMENTS.md` exists
   - If not found, tell user: "❌ Initiative not found: $ARGUMENTS. First create it with: /ccpm:initiative-new $ARGUMENTS"
   - Stop execution if initiative doesn't exist

2. **Verify branch exists:**
   ```bash
   git branch --list "initiative/$ARGUMENTS" | grep -q "initiative/$ARGUMENTS" || echo "❌ No branch for initiative: $ARGUMENTS"
   ```
   If branch doesn't exist, stop execution.

3. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, warn: "❌ Uncommitted changes detected. Commit or stash changes before merging."

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-merge || true`

## Instructions

### 1. Merge Pending Epic Branches

Check for unmerged epic branches belonging to this initiative:
```bash
git checkout initiative/$ARGUMENTS
```

List epic branches:
```bash
git branch --list "epic/*" 2>/dev/null | sed 's/^[* ]*//'
```

For each branch in the output, check if it has unmerged commits by running:
```bash
git log initiative/$ARGUMENTS..{branch} --oneline 2>/dev/null
```

If any output is produced, that branch has unmerged commits.

For each unmerged epic branch found:
1. Attempt merge into the initiative branch:
   ```bash
   git checkout initiative/$ARGUMENTS
   git merge $branch --no-ff -m "Merge $branch into initiative/$ARGUMENTS"
   ```
2. If merge succeeds:
   - Clean up worktree if one exists for this epic
   - Delete the epic branch (local + remote)
   - Log: "✅ Merged $branch into initiative/$ARGUMENTS"
3. If merge conflicts occur:
   - Abort: `git merge --abort`
   - Stop and report: "❌ Merge conflict merging $branch. Resolve manually, then retry."
   - Do not continue with remaining epics

### 2. Validate Epic Completion

Use the Glob tool to find all epic files matching `.pm/initiatives/$ARGUMENTS/*/epic.md`.

For each epic file found, use the Read tool to extract the `status:` field from frontmatter.

If any epic has status != "completed":
```
⚠️ Incomplete epics detected:

- {epic_name}: status={status}
- {epic_name}: status={status}

Continue with merge anyway? (yes/no)
```

Only proceed with explicit 'yes' confirmation. If user says no, suggest: "Complete remaining epics first, then retry: /ccpm:initiative-merge $ARGUMENTS"

### 3. Run Tests (Optional but Recommended)

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

### 4. Update Initiative Status

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Update `.pm/initiatives/$ARGUMENTS.md` frontmatter:
- Set `status` to "complete"
- Set `updated` to current datetime
- Set `completed` to current datetime

### 5. Attempt Merge

```bash
# Ensure main is up to date
git checkout main
git pull origin main
```

Before merging, build the commit message:
1. Use the Glob tool to find all epic files matching `.pm/initiatives/$ARGUMENTS/*/epic.md`
2. Use the Read tool to extract the `name:` field from each epic file's frontmatter to build the completed epics list

Then perform the merge:
```bash
git merge initiative/$ARGUMENTS --no-ff -m "Merge initiative: $ARGUMENTS

Completed epics:
{epic_list built from epic names}"
```

### 6. Handle Merge Conflicts

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

Branch preserved: initiative/$ARGUMENTS
```

### 7. Post-Merge Cleanup

If merge succeeds:
```bash
# Push to remote
git push origin main

# Delete branch
git branch -d initiative/$ARGUMENTS
git push origin --delete initiative/$ARGUMENTS 2>/dev/null || true

# Archive initiative directory
mkdir -p .pm/initiatives/archived/
mv .pm/initiatives/$ARGUMENTS .pm/initiatives/archived/$ARGUMENTS
echo "✅ Initiative archived: .pm/initiatives/archived/$ARGUMENTS/"
```

If `.pm/` is under version control, commit the archive move. Run:
```bash
git check-ignore -q .pm/
```
If the command fails (exit 1), `.pm/` is tracked — commit the archive:
```bash
git add .pm/initiatives/
git commit -m "Archive initiative: $ARGUMENTS"
git push origin main
```
If the command succeeds (exit 0), `.pm/` is gitignored — skip the commit and note: "ℹ️ .pm/ is gitignored — archive is local only"

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 8. Final Output

```
✅ Initiative Merged Successfully: $ARGUMENTS

Summary:
  Branch: initiative/$ARGUMENTS → main
  Commits merged: {count}
  Files changed: {count}
  Epics completed: {count}
    {list of epic names}

Cleanup completed:
  ✓ Branch deleted
  ✓ Initiative archived to .pm/initiatives/archived/$ARGUMENTS/

Next steps:
  - Deploy changes if needed
  - Start a new initiative: /ccpm:initiative-new {feature}
  - View completed work: git log --oneline -20
```

## Conflict Resolution Help

If conflicts need resolution:
```
The initiative branch has conflicts with main.

This typically happens when:
- Main has changed since the initiative started
- Multiple initiatives modified the same files
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
- Use --no-ff to preserve initiative history
- Archive initiative data instead of deleting
- Validate epic completion before merging
