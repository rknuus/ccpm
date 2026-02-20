---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS)
---

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open epic $ARGUMENTS epic-show || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/epic-show.sh $ARGUMENTS

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`
