---
allowed-tools: Bash, Read, Write, LS, Task
---

# Initiative Decompose

Decompose an initiative into multiple epic outlines (1-10 epics).

## Usage
```
/ccpm:initiative-decompose <initiative_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time
- `.claude/rules/branch-operations.md` - For branch creation

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

### Validation Steps
1. **Verify <initiative_name> was provided as a parameter:**
   - If not, tell user: "❌ <initiative_name> was not provided as parameter. Please run: /ccpm:initiative-decompose <initiative_name>"
   - Stop execution if <initiative_name> was not provided

2. **Verify Initiative exists:**
   - Check if `.pm/initiatives/$ARGUMENTS.md` exists
   - If not found, tell user: "❌ Initiative not found: $ARGUMENTS. First create it with: /ccpm:initiative-new $ARGUMENTS"
   - Stop execution if Initiative doesn't exist

3. **Validate Initiative frontmatter:**
   - Verify Initiative has valid frontmatter with: name, description, status, created
   - If frontmatter is invalid or missing, tell user: "❌ Invalid Initiative frontmatter. Please check: .pm/initiatives/$ARGUMENTS.md"
   - Show what's missing or invalid

4. **Check for existing epic directories:**
   - Count existing subdirectories in `.pm/initiatives/$ARGUMENTS/`
   - If any epic directories exist, list them and ask: "⚠️ Found {count} existing epic(s) under this initiative. Overwrite? (yes/no)"
   - Only proceed with explicit 'yes' confirmation
   - If user says no, suggest: "View existing epics with: /ccpm:initiative-status $ARGUMENTS"

5. **Verify directory permissions:**
   - Ensure `.pm/initiatives/$ARGUMENTS/` directory exists or can be created
   - If cannot create, tell user: "❌ Cannot create initiative directory. Please check permissions."

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-decompose || true`

## Instructions

You are a technical lead decomposing an Initiative into multiple epic outlines for: **$ARGUMENTS**

**Hard limit: A maximum of 10 epics per initiative.** This limit is strictly enforced. If analysis suggests more than 10 epics, consolidate related work into fewer, broader epics.

### 1. Read the Initiative
- Load the Initiative from `.pm/initiatives/$ARGUMENTS.md`
- Analyze all requirements, constraints, and scope
- Understand the user stories and success criteria
- Extract the Initiative description from frontmatter

### 2. Identify Epic Boundaries
- Break the initiative into 1-10 logical epics based on:
  - Functional boundaries (distinct features or capabilities)
  - Technical boundaries (different subsystems or layers)
  - Delivery boundaries (independent shippable increments)
  - Team boundaries (work that can proceed in parallel)
- Identify dependencies between epics
- Ensure each epic is independently valuable when possible
- **Enforce the 10-epic maximum** — if you identify more than 10 areas of work, merge related areas until you have at most 10 epics
- Validate that all epic names are unique within the initiative

### 3. Create or Enter Branch
Follow the rules from `.claude/rules/branch-operations.md`:
```bash
# Check for uncommitted changes
git status --porcelain

# Create or checkout the initiative branch
git checkout -b initiative/$ARGUMENTS 2>/dev/null || git checkout initiative/$ARGUMENTS

# Push with optional fallback (no remote is OK)
git push -u origin initiative/$ARGUMENTS 2>/dev/null || echo "ℹ️ No remote configured — continuing with local branch only"
```

### 4. Create Epic Outlines
For each identified epic, create the directory and epic file.

**Directory structure:**
```
.pm/initiatives/$ARGUMENTS/
  {epic-name-1}/epic.md
  {epic-name-2}/epic.md
  ...
```

**Epic file format** — create `.pm/initiatives/$ARGUMENTS/{epic-name}/epic.md` with this exact structure:

```markdown
---
name: {epic-name}
status: backlog
created: [Current ISO date/time]
progress: 0%
initiative: .pm/initiatives/$ARGUMENTS.md
depends_on: []  # List other epic names within this initiative
architect: off
---

# Epic: {epic-name}

## Overview
Brief summary of what this epic covers and its role within the initiative.

## Scope
- Key deliverables and boundaries
- What is included
- What is explicitly excluded

## Dependencies
- Other epics in this initiative that must complete first (match depends_on field)
- External dependencies outside this initiative
```

**Note:** Epic outlines are intentionally rough-scoped. They contain only the overview, scope, and dependencies. Detailed technical breakdown, task decomposition, and implementation strategy happen later via `/ccpm:epic-decompose`.

### 5. Frontmatter Guidelines
- **name**: Use a short, descriptive kebab-case name for the epic
- **status**: Always start with "backlog" for new epics
- **created**: Get REAL current datetime by running: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh`
- **progress**: Always start with "0%" for new epics
- **initiative**: Reference the source Initiative file path
- **depends_on**: List epic names (not paths) that this epic depends on within the initiative, e.g., `[auth-backend, data-models]`
- **architect**: Default to "off"

### 6. Epic Count Enforcement
Before writing any files, verify the total epic count:
- Count the epics you plan to create
- If the count exceeds 10, stop and consolidate until the count is 10 or fewer
- After creating files, verify the count: `ls -d .pm/initiatives/$ARGUMENTS/*/epic.md 2>/dev/null | wc -l`
- If verification shows more than 10, report error and remove extras

### 7. Quality Validation

Before finalizing, verify:
- [ ] All Initiative requirements are covered across the epics
- [ ] No two epics have the same name
- [ ] Dependencies between epics are consistent (if A depends on B, B exists)
- [ ] Each epic has a clear, distinct scope
- [ ] Total epic count is between 1 and 10
- [ ] Epic names use kebab-case

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 8. Post-Creation

After successfully creating the epic outlines:
1. Confirm: "✅ Created {count} epic outlines for initiative: $ARGUMENTS"
2. Show summary:
   - List of created epics with their dependency relationships
   - Suggested execution order based on dependencies
3. Suggest next steps:
   - ➡️ `/ccpm:epic-decompose {epic-name}` — Break an epic into detailed tasks
   - `/ccpm:initiative-status $ARGUMENTS` — View initiative progress
   - `/ccpm:initiative-edit $ARGUMENTS` — Edit the source Initiative

## Error Recovery

If any step fails:
- If epic creation partially completes, list which epics were created
- Provide option to clean up partial epics
- Never leave the initiative in an inconsistent state
- If Initiative is incomplete, list specific missing sections
- If epic boundaries are unclear, identify what needs clarification

Focus on creating well-scoped, independently deliverable epic outlines that collectively cover all Initiative requirements for "$ARGUMENTS".
