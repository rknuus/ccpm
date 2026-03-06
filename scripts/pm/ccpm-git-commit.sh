#!/bin/bash
# ccpm-git-commit.sh — Stage files and commit with a message from a file.
#
# Usage: bash scripts/pm/ccpm-git-commit.sh <message-file> [files...]
#
# If files are specified, only those are staged. If omitted, stages all changes.
# The commit message is read from <message-file>.
#
# This avoids the $(cat <<'EOF'...) heredoc pattern that triggers extra
# Claude Code approval prompts.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: ccpm-git-commit.sh <message-file> [files...]" >&2
  exit 1
fi

MSG_FILE="$1"
shift

if [ ! -f "$MSG_FILE" ]; then
  echo "Error: Message file not found: $MSG_FILE" >&2
  exit 1
fi

if [ $# -gt 0 ]; then
  git add "$@"
else
  git add -A
fi

git commit -F "$MSG_FILE"
