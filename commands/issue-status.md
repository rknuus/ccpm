---
allowed-tools: Read, LS
---

# Issue Status

Check issue status and current state from local task files.

## Usage
```
/ccpm:issue-status <issue_number>
```

## Instructions

You are checking the current status of a task from local files for: **Issue #$ARGUMENTS**

### 1. Find Local Task File
- First check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists (new layout)
- Fall back to `.pm/epics/*/$ARGUMENTS.md` (old layout)
- If not found: "❌ No local task for #$ARGUMENTS"

### 2. Status Display
Read the task file frontmatter and show concise status:
```
Issue #$ARGUMENTS: {name from frontmatter}

Status: {status from frontmatter}
Created: {created from frontmatter}
Updated: {updated from frontmatter}
Dependencies: {depends_on from frontmatter}
Parallel: {parallel from frontmatter}
```

### 3. Epic Context
Determine the epic from the task file's parent directory. Read the epic.md file:
```
Epic Context:
  Epic: {epic_name}
  Epic progress: {completed_tasks}/{total_tasks} tasks complete
```

### 4. Actionable Next Steps
Based on status, suggest actions:
```
Suggested Actions:
  - Start work: /ccpm:issue-start $ARGUMENTS
  - Close issue: /ccpm:issue-close $ARGUMENTS
  - Reopen issue: /ccpm:issue-reopen $ARGUMENTS
```

Keep the output concise but informative for quick status checks.
