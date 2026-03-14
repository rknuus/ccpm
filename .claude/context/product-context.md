---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# Product Context

## Target Users

### Primary: Solo Developers Using Claude Code
- Use AI agents for feature development
- Need structure to avoid "vibe coding"
- Want to track what AI did and why
- Work on multiple features in parallel

### Secondary: Small Teams with AI-Assisted Development
- Multiple Claude instances on the same project
- Need coordination between human and AI work
- Want GitHub-native progress visibility
- Require audit trails for code reviews

## Core Use Cases

1. **Feature Development**: Initiative → Epic → Tasks → Code, with full traceability
2. **Parallel Execution**: Multiple AI agents working on different parts simultaneously
3. **Progress Tracking**: Real-time visibility via GitHub issues and local dashboards
4. **Context Preservation**: No more re-explaining project state to Claude each session
5. **Stats & Analytics**: Track token usage, working time, and satisfaction per feature

## User Journeys

### New Feature Flow
1. `/ccpm:initiative-new feature-name` — brainstorm requirements
2. `/ccpm:initiative-parse feature-name` — create technical epic
3. `/ccpm:epic-oneshot feature-name` — decompose, sync to GitHub, start work
4. Follow-up prompts for refinement — auto-tracked via hooks
5. `/ccpm:epic-merge feature-name` — merge to main

### Post-Completion Iteration
After an epic completes, users often enter follow-up prompts to fix issues without invoking CCPM commands. The `ccpm-context reopen` mechanism automatically tracks these sessions in stats.

## Constraints

- Must work without GitHub (local-only mode)
- Must work as a Claude Code plugin (no standalone CLI)
- All state in `.pm/` directory (portable, gitignored in consumer projects)
- No external databases or services beyond GitHub
