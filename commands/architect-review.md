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

1. **Verify epic exists:**
   ```bash
   test -f .pm/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found: $ARGUMENTS"
   ```

2. **Parse arguments:**
   Extract from `$ARGUMENTS`:
   - `epic_name`: First positional argument
   - `checkpoint`: Value after `--checkpoint` (required: `design`, `plan`, or `code`)
   - `task_id`: Value after `--task` (required for `plan` and `code` checkpoints)
   - `force`: Whether `--force` flag is present

3. **Check architect mode:**
   ```bash
   architect_mode=$(grep '^architect:' .pm/epics/$epic_name/epic.md | sed 's/^architect: *//')
   ```
   - If empty or `off` and no `--force` flag:
     "ℹ️ Architect review is disabled for this epic. Set `architect: advisory` or `architect: gate` in epic frontmatter to enable, or use `--force`."
   - If `--force` is present, proceed regardless of mode (treat as advisory)

4. **Validate checkpoint parameter:**
   - If `--checkpoint` not provided: "❌ Missing --checkpoint parameter. Use: design, plan, or code"
   - If `plan` or `code` and `--task` not provided: "❌ --task parameter required for plan/code checkpoints"
   - If `--task` provided, verify task file exists: `.pm/epics/$epic_name/$task_id.md`

## Instructions

### 1. Gather Context

Based on checkpoint type, collect the review context:

#### For `design` checkpoint:
```bash
# Read epic overview and architecture decisions
cat .pm/epics/$epic_name/epic.md

# Read all task files
for task_file in .pm/epics/$epic_name/[0-9]*.md; do
  [ -f "$task_file" ] || continue
  echo "=== $(basename $task_file) ==="
  cat "$task_file"
done
```

#### For `plan` checkpoint:
```bash
# Read epic overview (architecture decisions section)
cat .pm/epics/$epic_name/epic.md

# Read the specific task
cat .pm/epics/$epic_name/$task_id.md

# Check for any in-progress tasks that might conflict
for task_file in .pm/epics/$epic_name/[0-9]*.md; do
  [ -f "$task_file" ] || continue
  if grep -q '^status: in-progress' "$task_file"; then
    echo "=== In-progress: $(basename $task_file) ==="
    grep '^name:\|^conflicts_with:' "$task_file"
  fi
done
```

#### For `code` checkpoint:
```bash
# Read epic overview (architecture decisions section)
cat .pm/epics/$epic_name/epic.md

# Read the task specification
cat .pm/epics/$epic_name/$task_id.md

# Get the git diff for recent changes
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

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

If `.pm/epics/$epic_name/architect-log.md` does not exist, create it:
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

Determine the architect mode:
```bash
architect_mode=$(grep '^architect:' .pm/epics/$epic_name/epic.md | sed 's/^architect: *//')
```

**If gate mode and verdict is "Needs Changes":**
```
❌ Architect review: Needs Changes

{summary of critical findings}

Fix issues and re-run this command.
See full review: .pm/epics/{epic_name}/architect-log.md
```

**If gate mode and verdict is "Approved":**
```
✅ Architect review: Approved
See full review: .pm/epics/{epic_name}/architect-log.md
```

**If advisory mode (or --force):**
```
ℹ️ Architect review: {verdict}
See full review: .pm/epics/{epic_name}/architect-log.md
```

## Error Handling

- If architect agent fails: "❌ Architect review failed. Run manually or skip with --force"
- If log file write fails: Report the review output directly in the terminal
- Never block the user from proceeding in advisory mode

## Important Notes

- The architect never modifies code or task files -- it only writes to the log
- Follow `/rules/frontmatter-operations.md` for timestamp formatting
- Follow `/rules/standard-patterns.md` for error messages
