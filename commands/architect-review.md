---
allowed-tools: Bash, Read, Write, LS, Task
---

# Architect Review

Run an architectural review at a specific workflow checkpoint.

## Usage
```
/ccpm:architect-review <epic_name> --checkpoint design|plan|code [--task <task_id>] [--force]
```

## Quick Check

### Resolve Epic Path
Determine the epic directory (`{epic_dir}`):
1. Check `.pm/initiatives/*/$epic_name/epic.md` (new layout)
2. Fall back to `{epic_dir}/epic.md` (old layout)
Use the first path found.

1. **Verify epic exists:**
   ```bash
   test -f {epic_dir}/epic.md || echo "❌ Epic not found: $ARGUMENTS"
   ```

2. **Parse arguments:**
   Extract from `$ARGUMENTS`:
   - `epic_name`: First positional argument
   - `checkpoint`: Value after `--checkpoint` (required: `design`, `plan`, or `code`)
   - `task_id`: Value after `--task` (required for `plan` and `code` checkpoints)
   - `force`: Whether `--force` flag is present

3. **Check architect mode:**
   Use the Read tool to read `{epic_dir}/epic.md` and extract the `architect:` field from frontmatter.
   - If empty or `off` and no `--force` flag:
     "ℹ️ Architect review is disabled for this epic. Set `architect: advisory` or `architect: gate` in epic frontmatter to enable, or use `--force`."
   - If `--force` is present, proceed regardless of mode (treat as advisory)

4. **Validate checkpoint parameter:**
   - If `--checkpoint` not provided: "❌ Missing --checkpoint parameter. Use: design, plan, or code"
   - If `plan` or `code` and `--task` not provided: "❌ --task parameter required for plan/code checkpoints"
   - If `--task` provided, verify task file exists: `{epic_dir}/$task_id.md`

## Instructions

### 1. Gather Context

Based on checkpoint type, collect the review context:

#### For `design` checkpoint:
- Use the Read tool to read `{epic_dir}/epic.md`
- Use the Glob tool to find all task files matching `{epic_dir}/[0-9]*.md`
- Use the Read tool to read each task file

#### For `plan` checkpoint:
- Use the Read tool to read `{epic_dir}/epic.md` (architecture decisions section)
- Use the Read tool to read `{epic_dir}/$task_id.md`
- Use the Grep tool to search for `^status: in-progress` in `{epic_dir}/[0-9]*.md` to find any in-progress tasks that might conflict
- For each in-progress task found, use the Read tool to extract `name:` and `conflicts_with:` fields

#### For `code` checkpoint:
- Use the Read tool to read `{epic_dir}/epic.md` (architecture decisions section)
- Use the Read tool to read `{epic_dir}/$task_id.md`
- Get the git diff for recent changes:
  ```bash
  git diff HEAD~5 --stat
  git diff HEAD~5
  ```

### 2. Invoke Architect Agent

Use the Task tool to launch the architect agent:

```yaml
Task:
  description: "Architect review: {checkpoint} for {epic_name}"
  subagent_type: "general-purpose"
  prompt: |
    You are performing an architect review.

    **Checkpoint**: {checkpoint}
    **Epic**: {epic_name}
    {if task_id: **Task**: {task_id}}

    Read the architect agent definition from agents/architect.md for your review methodology.

    **Context to review:**
    {gathered context from step 1}

    Produce your review in the exact output format specified in agents/architect.md:
    - ARCHITECT REVIEW header with checkpoint, scope, verdict
    - FINDINGS with severity levels
    - RECOMMENDATIONS
    - RATIONALE

    Be concise. Only flag real issues.
```

### 3. Append to Architect Log

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh` to get the current datetime.

If `{epic_dir}/architect-log.md` does not exist, create it:
```markdown
---
epic: {epic_name}
created: {current_datetime}
---

# Architect Log: {epic_name}
```

Append the review entry:
```markdown

---

## Review: {checkpoint} - {subject} ({current_datetime})

**Verdict**: {verdict from agent}

### Findings
{findings from agent}

### Recommendations
{recommendations from agent}

### Rationale
{rationale from agent}
```

Where `{subject}` is:
- `design`: "Task Breakdown"
- `plan`: "Task #{task_id}"
- `code`: "Code Changes for Task #{task_id}"

### 4. Report Result

Determine the architect mode by using the Read tool to read `{epic_dir}/epic.md` and extracting the `architect:` field from frontmatter.

**If gate mode and verdict is "Needs Changes":**
```
❌ Architect review: Needs Changes

{summary of critical findings}

Fix issues and re-run this command.
See full review: {epic_dir}/architect-log.md
```

**If gate mode and verdict is "Approved":**
```
✅ Architect review: Approved
See full review: {epic_dir}/architect-log.md
```

**If advisory mode (or --force):**
```
ℹ️ Architect review: {verdict}
See full review: {epic_dir}/architect-log.md
```

## Error Handling

- If architect agent fails: "❌ Architect review failed. Run manually or skip with --force"
- If log file write fails: Report the review output directly in the terminal
- Never block the user from proceeding in advisory mode

## Important Notes

- The architect never modifies code or task files -- it only writes to the log
- Follow `/rules/frontmatter-operations.md` for timestamp formatting
- Follow `/rules/standard-patterns.md` for error messages
