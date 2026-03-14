---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Sync

Push epic and tasks to GitHub as issues.

## Usage
```
/ccpm:epic-sync <feature_name>
```

## Quick Check

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`):
1. Check `.pm/initiatives/*/$ARGUMENTS/epic.md` (new layout)
2. Fall back to `{epic_dir}/epic.md` (old layout)
Use the first path found.

```bash
# Verify epic exists
test -f {epic_dir}/epic.md || echo "❌ Epic not found. Run: /ccpm:initiative-parse $ARGUMENTS"

# Count task files
ls {epic_dir}/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "❌ No tasks to sync. Run: /ccpm:epic-decompose $ARGUMENTS"

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open epic $ARGUMENTS epic-sync || true`

## Instructions

### 0. Check Remote Repository

Follow `/rules/github-operations.md` to ensure we're not syncing to the CCPM template:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-repo-check.sh
```

If the script exits with a non-zero status, stop execution.

### 1. Create Epic Issue

#### First, detect the GitHub repository:
Run `git remote get-url origin` to get the remote URL, then run `gh repo view --json nameWithOwner -q .nameWithOwner` to get the `OWNER/REPO` string. Use these values in subsequent steps.

Strip frontmatter and prepare GitHub issue body:
```bash
# Extract content without frontmatter
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh {epic_dir}/epic.md /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    # When we hit the next section after Tasks Created, add Stats
    if (total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort " hours"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }
  /^Estimated total effort:/ && in_tasks {
    gsub(/^Estimated total effort: /, "")
    total_effort = $0
    next
  }
  !in_tasks { print }
  END {
    # If we were still in tasks section at EOF, add stats
    if (in_tasks && total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md
```

Use the Grep tool to check if the epic body contains bug-related keywords (`bug|fix|issue|problem|error`). Set `epic_type` to `"bug"` if found, otherwise `"feature"`.

Create epic issue with labels:
```bash
gh issue create \
  --repo "$REPO" \
  --title "Epic: $ARGUMENTS" \
  --body-file /tmp/epic-body.md \
  --label "epic,epic:$ARGUMENTS,$epic_type"
```

Extract the returned issue number from the output.

Store the returned issue number for epic frontmatter update.

### 2. Create Task Sub-Issues

Check if gh-sub-issue is available:
```bash
gh extension list | grep -q "yahsan2/gh-sub-issue" && echo "available" || echo "unavailable"
```

Count task files to determine strategy:
```bash
ls {epic_dir}/[0-9]*.md 2>/dev/null | wc -l
```

### For Small Batches (< 5 tasks): Sequential Creation

For each task file in `{epic_dir}/[0-9]*.md`:

1. Use the Read tool to read the task file and extract the `name:` field from frontmatter.
2. Strip frontmatter:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh "$task_file" /tmp/task-body.md
   ```
3. Create sub-issue with labels:
   - If gh-sub-issue available:
     ```bash
     gh sub-issue create \
       --parent "$epic_number" \
       --title "$task_name" \
       --body-file /tmp/task-body.md \
       --label "task,epic:$ARGUMENTS"
     ```
   - Otherwise:
     ```bash
     gh issue create \
       --repo "$REPO" \
       --title "$task_name" \
       --body-file /tmp/task-body.md \
       --label "task,epic:$ARGUMENTS"
     ```
4. Record the mapping of task file to issue number.

### For Larger Batches: Parallel Creation

Use Task tool for parallel creation:
```yaml
Task:
  description: "Create GitHub sub-issues batch {X}"
  subagent_type: "general-purpose"
  prompt: |
    Create GitHub sub-issues for tasks in epic $ARGUMENTS
    Parent epic issue: #$epic_number

    Tasks to process:
    - {list of 3-4 task files}

    For each task file:
    1. Use the Read tool to extract task name from frontmatter
    2. Strip frontmatter using:
       bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-strip-frontmatter.sh "$task_file" /tmp/task-body.md
    3. Create sub-issue using:
       - If gh-sub-issue available:
         gh sub-issue create --parent $epic_number --title "$task_name" \
           --body-file /tmp/task-body.md --label "task,epic:$ARGUMENTS"
       - Otherwise:
         gh issue create --repo "$REPO" --title "$task_name" --body-file /tmp/task-body.md \
           --label "task,epic:$ARGUMENTS"
    4. Record: task_file:issue_number

    IMPORTANT: Always include --label parameter with "task,epic:$ARGUMENTS"

    Return mapping of files to issue numbers.
```

Consolidate results from parallel agents and proceed to step 3.

### 3. Rename Task Files and Update References

First, build a mapping of old numbers to new issue IDs from the collected task-file:issue-number pairs. For each pair, extract the old number from the filename (e.g., `001` from `001.md`).

Then for each task file and its corresponding new issue number:

1. Use the Read tool to read the task file content.
2. Replace all references to old task numbers (in `depends_on` and `conflicts_with` fields) with their new issue numbers using the Edit tool.
3. Use the Write tool to save the updated content to the new filename (`{issue_number}.md`).
4. Remove the old file if the name changed:
   ```bash
   rm "$old_task_file"
   ```
5. Run `gh repo view --json nameWithOwner -q .nameWithOwner` to get the repo identifier.
6. Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current timestamp.
7. Use the Edit tool to update the task file frontmatter:
   - Set `github:` to `https://github.com/{repo}/issues/{task_number}`
   - Set `updated:` to the current timestamp

### 4. Update Epic with Task List (Fallback Only)

If NOT using gh-sub-issue, add task list to epic:

```bash
# Get current epic body
gh issue view ${epic_number} --json body -q .body > /tmp/epic-body.md
```

Append the task list to `/tmp/epic-body.md` in this format:
```markdown
## Tasks
- [ ] #${task1_number} ${task1_name}
- [ ] #${task2_number} ${task2_name}
- [ ] #${task3_number} ${task3_name}
```

Then update the epic issue:
```bash
gh issue edit ${epic_number} --body-file /tmp/epic-body.md
```

With gh-sub-issue, this is automatic!

### 5. Update Epic File

Update the epic file with GitHub URL, timestamp, and real task IDs:

#### 5a. Update Frontmatter

1. Run `gh repo view --json nameWithOwner -q .nameWithOwner` to get the repo identifier.
2. Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current timestamp.
3. Use the Edit tool to update `{epic_dir}/epic.md` frontmatter:
   - Set `github:` to `https://github.com/{repo}/issues/{epic_number}`
   - Set `updated:` to the current timestamp

#### 5b. Update Tasks Created Section

1. Use the Glob tool to find all task files matching `{epic_dir}/[0-9]*.md`.
2. Use the Read tool to read each task file and extract `name:` and `parallel:` from frontmatter.
3. Build the new Tasks Created section with the real issue numbers and summary statistics.
4. Use the Edit tool to replace the existing `## Tasks Created` section in `epic.md` with the updated content.

### 6. Create Mapping File

1. Run `gh repo view --json nameWithOwner -q .nameWithOwner` to get the repo identifier.
2. Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current timestamp.
3. Use the Write tool to create `{epic_dir}/github-mapping.md` with the following content:

```markdown
# GitHub Issue Mapping

Epic: #{epic_number} - https://github.com/{repo}/issues/{epic_number}

Tasks:
- #{issue_num}: {task_name} - https://github.com/{repo}/issues/{issue_num}
...

Synced: {current_timestamp}
```

### 7. Create Worktree

Follow `/rules/worktree-operations.md` to create development worktree:

```bash
# Ensure main is current
git checkout main
git pull origin main

# Create worktree for epic
git worktree add ../epic-$ARGUMENTS -b epic/$ARGUMENTS

echo "Created worktree: ../epic-$ARGUMENTS"
```

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 8. Output

```
✅ Synced to GitHub
  - Epic: #{epic_number} - {epic_title}
  - Tasks: {count} sub-issues created
  - Labels applied: epic, task, epic:{name}
  - Files renamed: {local_id}.md → {issue_id}.md
  - References updated: depends_on/conflicts_with now use issue IDs
  - Worktree: ../epic-$ARGUMENTS

Next steps:
  - Start parallel execution: /ccpm:epic-start $ARGUMENTS
  - Or work on single issue: /ccpm:issue-start {issue_number}
  - View epic: https://github.com/{owner}/{repo}/issues/{epic_number}
```

## Error Handling

Follow `/rules/github-operations.md` for GitHub CLI errors.

If any issue creation fails:
- Report what succeeded
- Note what failed
- Don't attempt rollback (partial sync is fine)

## Important Notes

- Trust GitHub CLI authentication
- Don't pre-check for duplicates
- Update frontmatter only after successful creation
- Keep operations simple and atomic
