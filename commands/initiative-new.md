---
allowed-tools: Bash, Read, Write, LS
---

# Initiative New

Launch brainstorming for new initiative document.

## Usage
```
/ccpm:initiative-new <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

### Input Validation
1. **Validate feature name format:**
   - Must contain only lowercase letters, numbers, and hyphens
   - Must start with a letter
   - No spaces or special characters allowed
   - If invalid, tell user: "❌ Feature name must be kebab-case (lowercase letters, numbers, hyphens only). Examples: user-auth, payment-v2, notification-system"

2. **Check for existing Initiative:**
   - Check if `.pm/initiatives/$ARGUMENTS.md` already exists
   - If it exists, ask user: "⚠️ Initiative '$ARGUMENTS' already exists. Do you want to overwrite it? (yes/no)"
   - Only proceed with explicit 'yes' confirmation
   - If user says no, suggest: "Use a different name or run: /ccpm:initiative-decompose $ARGUMENTS to create an epic from the existing Initiative"

3. **Verify directory structure:**
   - Check if `.pm/initiatives/` directory exists
   - If not, create it first
   - If unable to create, tell user: "❌ Cannot create Initiative directory. Please manually create: .pm/initiatives/"

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-new || true`

## Instructions

You are a product manager creating a comprehensive Initiative document for: **$ARGUMENTS**

Follow this structured approach:

### 1. Discovery & Context
- Ask clarifying questions about the feature/product "$ARGUMENTS"
- Understand the problem being solved
- Identify target users and use cases
- Gather constraints and requirements
- Probe for domain concepts and their correctness properties:
  - **Identifiers**: Key entities, uniqueness scope, reuse rules
  - **State**: Valid states, allowed transitions, source of truth
  - **Ordering**: Ordered collections, invariants after mutations
  - **Consistency**: Multiple representations, disagreement handling
  - **Concurrency**: Concurrent modifications, conflict resolution
  - **Idempotency**: Which operations must be safe to retry

### 2. Initiative Structure
Create a comprehensive Initiative with these sections:

#### Executive Summary
- Brief overview and value proposition

#### Problem Statement
- What problem are we solving?
- Why is this important now?

#### User Stories
- Primary user personas
- Detailed user journeys
- Pain points being addressed
- When writing acceptance criteria, include any identified correctness properties inline (e.g., uniqueness, ordering invariants, concurrency expectations)

#### Requirements
**Functional Requirements**
- Core features and capabilities
- User interactions and flows
- When writing functional requirements, weave in correctness properties discovered during brainstorming (e.g., "Task IDs are unique within a board and never reused")

**Non-Functional Requirements**
- Performance expectations
- Security considerations
- Scalability needs

#### Success Criteria
- Measurable outcomes
- Key metrics and KPIs

#### Constraints & Assumptions
- Technical limitations
- Timeline constraints
- Resource limitations
- Include any consistency, concurrency, or idempotency assumptions surfaced during discovery

#### Out of Scope
- What we're explicitly NOT building

#### Dependencies
- External dependencies
- Internal team dependencies

### 3. File Format with Frontmatter
Save the completed Initiative to: `.pm/initiatives/$ARGUMENTS.md` with this exact structure:

```markdown
---
name: $ARGUMENTS
description: [Brief one-line description of the Initiative]
status: backlog
created: [Current ISO date/time]
---

# Initiative: $ARGUMENTS

## Executive Summary
[Content...]

## Problem Statement
[Content...]

[Continue with all sections...]
```

### 4. Frontmatter Guidelines
- **name**: Use the exact feature name (same as $ARGUMENTS)
- **description**: Write a concise one-line summary of what this Initiative covers
- **status**: Always start with "backlog" for new Initiatives
- **created**: Get REAL current datetime by running: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-datetime.sh`
  - Never use placeholder text
  - Must be actual system time in ISO 8601 format

### 5. Quality Checks

Before saving the Initiative, verify:
- [ ] All sections are complete (no placeholder text)
- [ ] User stories include acceptance criteria
- [ ] Success criteria are measurable
- [ ] Dependencies are clearly identified
- [ ] Out of scope items are explicitly listed

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`

### 6. Post-Creation

After successfully creating the Initiative:
1. Confirm: "✅ Initiative created: .pm/initiatives/$ARGUMENTS.md"
2. Show brief summary of what was captured
3. Suggest next steps — three workflows available:
   - **Simple** (all-in-one): `/ccpm:initiative-go $ARGUMENTS` — Parse, decompose, start agents in one step
   - **Step-by-step** (single epic): `/ccpm:initiative-decompose $ARGUMENTS` → `epic-decompose` → `epic-start` → `initiative-merge`
   - **Multi-epic** (large initiatives): `/ccpm:initiative-decompose $ARGUMENTS` → `epic-decompose` per epic → `epic-start-all` → `initiative-merge`
   - `/ccpm:initiative-edit $ARGUMENTS` — Edit the Initiative

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- Provide specific steps to fix the issue
- Never leave partial or corrupted files

Conduct a thorough brainstorming session before writing the Initiative. Ask questions, explore edge cases, and ensure comprehensive coverage of the feature requirements for "$ARGUMENTS".
