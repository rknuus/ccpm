---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh)
---

### Context Tracking
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context open prd $ARGUMENTS prd-status || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh

### Close Context
Run: `${CLAUDE_PLUGIN_ROOT}/scripts/pm/ccpm-context close || true`
