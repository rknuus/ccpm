---
created: 2026-03-01T22:10:52Z
last_updated: 2026-03-01T22:10:52Z
version: 1.0
author: Claude Code PM System
---

# Project Brief

## What It Is

CCPM (Claude Code Project Manager) is a Claude Code plugin that provides a spec-driven development workflow. It turns Initiatives into epics, epics into GitHub issues, and issues into production code — with full traceability at every step.

## Why It Exists

AI-assisted development suffers from:
- **Context loss** between sessions, forcing constant re-discovery
- **Parallel work conflicts** when multiple developers touch the same code
- **Requirements drift** as verbal decisions override written specs
- **Invisible progress** until the very end

CCPM solves these by enforcing a structured workflow: brainstorm → document → plan → execute → track.

## Repository

- **Origin**: `git@github.com:rknuus/ccpm.git` (fork of `automazeio/ccpm`)
- **License**: MIT
- **Primary language**: Bash (shell scripts)

## Success Criteria

- Every line of code traces back to a specification
- Multiple AI agents can work on the same project simultaneously
- Progress is transparent and auditable via GitHub issues
- The plugin works both locally (no GitHub) and with full GitHub integration

## Core Principle

> No Vibe Coding — every line of code must trace back to a specification.

Five-phase discipline: Brainstorm → Document → Plan → Execute → Track.
