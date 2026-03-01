#!/bin/bash
# Hook: auto-reopen last context on user prompt submission.
#
# Called by Claude Code's UserPromptSubmit hook. Reopens the most recent
# closed context if it ended less than 30 minutes ago, so that follow-up
# prompts outside CCPM commands are still tracked in stats.
#
# Setup: add this to your project's .claude/settings.json (or settings.local.json):
#
#   "hooks": {
#     "UserPromptSubmit": [{
#       "hooks": [{ "type": "command", "command": "<plugin_path>/scripts/pm/hook-auto-context.sh" }]
#     }],
#     "SessionEnd": [{
#       "hooks": [{ "type": "command", "command": "<plugin_path>/scripts/pm/ccpm-context close" }]
#     }]
#   }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/ccpm-context" reopen 30
exit 0
