---
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/init.sh)
---

This command is **optional**. Most CCPM commands create the `.pm/` directories they need on the fly. Running `/ccpm:init` is recommended when you want to:

- Pre-create the full `.pm/` directory structure
- Copy CCPM rules to `.claude/rules/` (useful for non-plugin installations)

Output:
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/init.sh
