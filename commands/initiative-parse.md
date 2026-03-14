---
allowed-tools: Bash, Read, Write, LS
---

# Initiative Parse

Convert Initiative to technical implementation epic.

## Usage
```
/ccpm:initiative-parse <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

### Validation Steps
1. **Verify <feature_name> was provided as a parameter:**
   - If not, tell user: "❌ <feature_name> was not provided as parameter. Please run: /ccpm:initiative-parse <feature_name>"
   - Stop execution if <feature_name> was not provided

2. **Verify Initiative exists:**
   - Check if `.pm/initiatives/$ARGUMENTS.md` exists
   - If not found, tell user: "❌ Initiative not found: $ARGUMENTS. First create it with: /ccpm:initiative-new $ARGUMENTS"
   - Stop execution if Initiative doesn't exist

3. **Validate Initiative frontmatter:**
   - Verify Initiative has valid frontmatter with: name, description, status, created
   - If frontmatter is invalid or missing, tell user: "❌ Invalid Initiative frontmatter. Please check: .pm/initiatives/$ARGUMENTS.md"
   - Show what's missing or invalid

4. **Check for existing epic:**
   - Check if `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md` already exists
   - If not found, also check old location `.pm/epics/$ARGUMENTS/epic.md` as fallback
   - If it exists at either location, ask user: "⚠️ Epic '$ARGUMENTS' already exists. Overwrite? (yes/no)"
   - Only proceed with explicit 'yes' confirmation
   - If user says no, suggest: "View existing epic with: /ccpm:epic-show $ARGUMENTS"

5. **Verify directory permissions:**
   - Ensure `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/` directory exists or can be created
   - If cannot create, tell user: "❌ Cannot create epic directory. Please check permissions."

6. **Create or enter initiative branch:**
   - Create `initiative/$ARGUMENTS` branch from main (or enter it if it already exists):
     ```bash
     git checkout main && git pull origin main 2>/dev/null; git checkout -b initiative/$ARGUMENTS 2>/dev/null || git checkout initiative/$ARGUMENTS
     ```
   - Push with optional fallback:
     ```bash
     git push -u origin initiative/$ARGUMENTS 2>/dev/null || echo "ℹ️ No remote configured — continuing with local branch only"
     ```

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-parse || true`

## Instructions

You are a technical lead converting an Initiative document into a detailed implementation epic for: **$ARGUMENTS**

### 1. Read the Initiative
- Load the Initiative from `.pm/initiatives/$ARGUMENTS.md`
- Analyze all requirements and constraints
- Understand the user stories and success criteria
- Extract the Initiative description from frontmatter

### 2. Technical Analysis
- Identify architectural decisions needed
- Determine technology stack and approaches
- Map functional requirements to technical components
- Identify integration points and dependencies
- For each correctness property identified in the Initiative (uniqueness, ordering, consistency, idempotency, etc.):
  - Determine which layer (frontend, backend, database) is responsible for enforcement
  - Identify failure modes if the property is violated
  - Call out edge cases (e.g., concurrent edits, archived items, retry scenarios)

### 3. File Format with Frontmatter
Create the epic file at: `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md` with this exact structure:

```markdown
---
name: $ARGUMENTS
status: backlog
created: [Current ISO date/time]
progress: 0%
initiative: .pm/initiatives/$ARGUMENTS.md
github: [Will be updated when synced to GitHub]
architect: off  # Set to 'advisory' or 'gate' to enable architect reviews
---

# Epic: $ARGUMENTS

## Overview
Brief technical summary of the implementation approach

## Architecture Decisions
- Key technical decisions and rationale
- Technology choices
- Design patterns to use

## Technical Approach
### Frontend Components
- UI components needed
- State management approach
- User interaction patterns

### Backend Services
- API endpoints required
- Data models and schema
- Business logic components

### Infrastructure
- Deployment considerations
- Scaling requirements
- Monitoring and observability

### Correctness Enforcement
For each critical property from the Initiative, document: the responsible layer (frontend/backend/database),
failure modes if violated, and relevant edge cases. Integrate these inline in the sections above
where appropriate rather than listing them all here.

## Implementation Strategy
- Development phases
- Risk mitigation
- Testing approach

## Task Breakdown Preview
High-level task categories that will be created:
- [ ] Category 1: Description
- [ ] Category 2: Description
- [ ] etc.

## Dependencies
- External service dependencies
- Internal team dependencies
- Prerequisite work

## Success Criteria (Technical)
- Performance benchmarks
- Quality gates
- Acceptance criteria

## Estimated Effort
- Overall timeline estimate
- Resource requirements
- Critical path items
```

### 4. Frontmatter Guidelines
- **name**: Use the exact feature name (same as $ARGUMENTS)
- **status**: Always start with "backlog" for new epics
- **created**: Get REAL current datetime by running: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh`
- **progress**: Always start with "0%" for new epics
- **initiative**: Reference the source Initiative file path
- **github**: Leave placeholder text - will be updated during sync
- **architect**: Default to "off". Set to "advisory" or "gate" to enable architect reviews at workflow checkpoints

### 5. Output Location
Create the directory structure if it doesn't exist:
- `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/` (directory)
- `.pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md` (epic file)

### 6. Quality Validation

Before saving the epic, verify:
- [ ] All Initiative requirements are addressed in the technical approach
- [ ] Task breakdown categories cover all implementation areas
- [ ] Dependencies are technically accurate
- [ ] Effort estimates are realistic
- [ ] Architecture decisions are justified

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 7. Post-Creation

After successfully creating the epic:
1. Confirm: "✅ Epic created: .pm/initiatives/$ARGUMENTS/$ARGUMENTS/epic.md"
2. Show summary of:
   - Number of task categories identified
   - Key architecture decisions
   - Estimated effort
3. Suggest next steps:
   - ➡️ `/ccpm:epic-decompose $ARGUMENTS` — Break epic into tasks
   - `/ccpm:initiative-go $ARGUMENTS` — Parse, decompose, and start agents (local-only, no GitHub sync)
   - `/ccpm:epic-edit $ARGUMENTS` — Edit the epic
   - `/ccpm:initiative-edit $ARGUMENTS` — Edit the source Initiative

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- If Initiative is incomplete, list specific missing sections
- If technical approach is unclear, identify what needs clarification
- Never create an epic with incomplete information

Focus on creating a technically sound implementation plan that addresses all Initiative requirements while being practical and achievable for "$ARGUMENTS".

## IMPORTANT:
- Aim for as few tasks as possible and limit the total number of tasks to 10 or less.
- When creating the epic, identify ways to simplify and improve it. Look for ways to leverage existing functionality instead of creating more code when possible.
