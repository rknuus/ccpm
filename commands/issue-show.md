---
allowed-tools: Read, LS
---

# Issue Show

Display detailed issue information from local task files.

## Usage
```
/ccpm:issue-show <issue_number>
```

## Instructions

You are displaying comprehensive information about a task for: **Issue #$ARGUMENTS**

### 1. Find Local Task File
- First check if `.pm/initiatives/*/*/$ARGUMENTS.md` exists (new layout)
- Fall back to `.pm/epics/*/$ARGUMENTS.md` (old layout)
- If not found: "❌ No local task for #$ARGUMENTS"

### 2. Issue Overview
Read the task file and display:
```
Issue #$ARGUMENTS: {name from frontmatter}
  Status: {status}
  Created: {created}
  Updated: {updated}
  Dependencies: {depends_on}
  Parallel: {parallel}
  Conflicts with: {conflicts_with}
```

Then display the full task body (everything after frontmatter).

### 3. Local Files
Show related files:
```
Local Files:
  Task file: {path to task file}
  Epic: {path to parent epic.md}
  Updates: {epic_dir}/updates/$ARGUMENTS/ (if exists)
```

### 4. Dependencies
Show dependency information from frontmatter:
```
Dependencies:
  Depends on: {list of task IDs}
  Conflicts with: {list of task IDs}
```

### 5. Quick Actions
```
Quick Actions:
  Start work: /ccpm:issue-start $ARGUMENTS
  Edit: /ccpm:issue-edit $ARGUMENTS
  Close: /ccpm:issue-close $ARGUMENTS
```

### 6. Error Handling
- Handle invalid task numbers gracefully
- Provide helpful alternatives if task not found

Provide comprehensive task information to help developers understand context and current status for Issue #$ARGUMENTS.
