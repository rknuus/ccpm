---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS)
---

### Context Tracking
Run: `source scripts/pm/context-lib.sh && stats_context_open epic $ARGUMENTS epic-show || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS

### Close Context
Run: `source scripts/pm/context-lib.sh && stats_context_close || true`
