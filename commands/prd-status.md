---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh)
---

**IMPORTANT:** Before proceeding, verify CCPM is initialized by checking if `.claude/rules/path-standards.md` exists. If it does not exist, stop immediately and tell the user: "CCPM not initialized. Run: /ccpm:init"

### Context Tracking
Run: `source scripts/pm/context-lib.sh && stats_context_open prd $ARGUMENTS prd-status || true`

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/prd-status.sh

### Close Context
Run: `source scripts/pm/context-lib.sh && stats_context_close || true`
