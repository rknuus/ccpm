---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/initiative-status.sh)
---

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open initiative $ARGUMENTS initiative-status || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/initiative-status.sh

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`
