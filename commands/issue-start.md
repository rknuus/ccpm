---
allowed-tools: Bash, Read, Write, LS, Task
---

# Issue Start

Begin work on a task with parallel agents based on work stream analysis.

## Usage
```
/ccpm:issue-start <issue_number>
```

## Quick Check

1. **Find local task file:**
   - Use the Glob tool to check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists
   - If not found: "❌ No local task for issue #$ARGUMENTS."
   - Extract `{epic_dir}` from the found task file's parent directory.

2. **Check for analysis:**
   - Use the Glob tool to check if `{epic_dir}/$ARGUMENTS-analysis.md` exists
   - If no analysis exists and no --analyze flag, stop execution with:
     "❌ No analysis found for issue #$ARGUMENTS. Run: /ccpm:issue-analyze $ARGUMENTS first. Or: /ccpm:issue-start $ARGUMENTS --analyze to do both"

## Instructions

### 1. Ensure Worktree Exists

Extract the epic name from the task file path. Then check if the epic worktree exists:
```bash
git worktree list | grep "epic-$epic_name"
```

If not found: "❌ No worktree for epic. Run: /ccpm:epic-start $epic_name"

### 2. Read Analysis

Use the Read tool to read `{epic_dir}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 3. Architect Review (Optional)

Use the Read tool to read `{epic_dir}/epic.md` and extract the `architect:` field from frontmatter.

If `architect_mode` is `gate` or `advisory`:
- Run: `/ccpm:architect-review $epic_name --checkpoint plan --task $ARGUMENTS`
- If gate mode and review returns "Needs Changes": report issues and stop (do not launch agents)
- If advisory mode: log findings and continue

If `architect_mode` is empty or `off`: skip silently.

### 4. Setup Progress Tracking

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

Create workspace structure:
```bash
mkdir -p {epic_dir}/updates/$ARGUMENTS
```

Use the Edit tool to update the task file frontmatter `updated` field with the current datetime.

### 5. Launch Parallel Agents

For each stream that can start immediately:

Use the Write tool to create `{epic_dir}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}

## Files
{file_patterns}

## Progress
- Starting implementation
```

Launch agent using Task tool:
```yaml
Task:
  description: "Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$ARGUMENTS in the epic worktree.

    Worktree location: ../epic-{epic_name}/
    Your stream: {stream_name}

    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}

    Requirements:
    1. Use the Read tool to read the full task from: {epic_dir}/{task_file}
    2. Work ONLY in your assigned files
    3. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    4. Update progress in: {epic_dir}/updates/$ARGUMENTS/stream-{X}.md
    5. Follow coordination rules in /rules/agent-coordination.md

    If you need to modify files outside your scope:
    - Check if another stream owns them
    - Wait if necessary
    - Update your progress file with coordination notes

    Complete your stream's work and mark as completed when done.
```

### 6. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Epic: {epic_name}
Worktree: ../epic-{epic_name}/

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  {epic_dir}/updates/$ARGUMENTS/

Monitor with: /ccpm:epic-status {epic_name}
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
