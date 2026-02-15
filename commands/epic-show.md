---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS)
---

**IMPORTANT:** Before proceeding, verify CCPM is initialized by checking if `.claude/rules/path-standards.md` exists. If it does not exist, stop immediately and tell the user: "CCPM not initialized. Run: /ccpm:init"

### Context Tracking
Run: `source scripts/pm/context-lib.sh && stats_context_open epic $ARGUMENTS epic-show || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS

### Close Context
Run: `source scripts/pm/context-lib.sh && stats_context_close || true`
