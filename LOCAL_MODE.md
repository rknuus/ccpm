# CCPM Local Mode

CCPM manages all project data through local markdown files in the `.pm/` directory.

## Workflow

### 1. Create Requirements (Initiative)
```bash
/ccpm:initiative-new user-authentication
```
- Creates: `.pm/initiatives/user-authentication.md`
- Output: Complete Initiative with requirements and user stories

### 2. Convert to Technical Plan (Epic)
```bash
/ccpm:initiative-decompose user-authentication
```
- Creates: `.pm/initiatives/user-authentication/user-authentication/epic.md`
- Output: Technical implementation plan

### 3. Break Down Into Tasks
```bash
/ccpm:epic-decompose user-authentication
```
- Creates: `.pm/initiatives/user-authentication/user-authentication/1.md`, `2.md`, etc.
- Output: Individual task files with acceptance criteria

### 4. View Your Work
```bash
/ccpm:epic-show user-authentication    # View epic and all tasks
/ccpm:status                           # Project dashboard
/ccpm:initiative-list                   # List all Initiatives
```

### 5. Work on Tasks
```bash
# View specific task details
cat .pm/initiatives/user-authentication/user-authentication/1.md

# Update task status manually
vim .pm/initiatives/user-authentication/user-authentication/1.md
```

## What Gets Created Locally

```text
.pm/
├── initiatives/
│   └── user-authentication.md      # Requirements document
├── epics/
│   └── user-authentication/
│       ├── epic.md                 # Technical plan
│       ├── 001.md                  # Task: Database schema
│       ├── 002.md                  # Task: API endpoints
│       └── 003.md                  # Task: UI components
└── stats/
    └── active-context.json         # Usage statistics
```

## Available Commands

- `/ccpm:initiative-new <name>` - Create requirements
- `/ccpm:initiative-decompose <name>` - Generate technical plan
- `/ccpm:epic-decompose <name>` - Break into tasks
- `/ccpm:epic-show <name>` - View epic and tasks
- `/ccpm:status` - Project dashboard
- `/ccpm:initiative-list` - List Initiatives
- `/ccpm:search <term>` - Search content
- `/ccpm:validate` - Check file integrity
- `/ccpm:stats` - Token usage and time overview
- `/ccpm:stats-show <name>` - Detailed stats for a specific item
- `/ccpm:stats-rate <name>` - Rate satisfaction with a completed item
- `/ccpm:context-create` - Generate project context documentation
- `/ccpm:context-update` - Refresh context with recent changes
- `/ccpm:context-prime` - Load context into current conversation
- `/ccpm:config` - Configure CCPM settings

## Benefits

- **No external dependencies** - Works without internet
- **Full privacy** - All data stays local
- **Version control friendly** - All files are markdown
- **Team collaboration** - Share `.claude/` directory via git
- **Customizable** - Edit templates and workflows freely
- **Fast** - No API calls or network delays

## Manual Task Management

Tasks are stored as markdown files with frontmatter:

```markdown
---
name: Implement user login API
status: open          # open, in-progress, completed
created: 2024-01-15T10:30:00Z
updated: 2024-01-15T10:30:00Z
parallel: true
depends_on: [001]
---

# Task: Implement user login API

## Description
Create POST /api/auth/login endpoint...

## Acceptance Criteria
- [ ] Endpoint accepts email/password
- [ ] Returns JWT token on success
- [ ] Validates credentials against database
```

Update the `status` field manually as you work:
- `open` → `in-progress` → `completed`

That's it! You have a complete project management system that works entirely offline.
