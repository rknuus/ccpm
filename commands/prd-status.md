---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh)
---

### Context Tracking
Run: `source scripts/pm/context-lib.sh && stats_context_open prd $ARGUMENTS prd-status || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh

### Close Context
Run: `source scripts/pm/context-lib.sh && stats_context_close || true`
