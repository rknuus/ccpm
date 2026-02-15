#!/bin/bash
# stats-prompts.sh — Prompt collection for CCPM stats.
# Source this file; do not execute directly.
#
# Provides:
#   stats_collect_prompts <type> <name>
#
# Requires: jq, stats-lib.sh (stats_extract_prompts, stats_find_jsonl_files),
#           context-lib.sh (stats_context_history)
#
# Integration note for stats display commands (Task 12):
#   source scripts/pm/stats-prompts.sh
#   Call stats_collect_prompts <type> <name> during stats computation.
#   It reads collectPrompts from .pm/ccpm-settings.json and only runs
#   when the setting is true. Safe to call unconditionally.

STATS_PROMPTS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies if not already loaded
if ! declare -f stats_extract_prompts &>/dev/null; then
  # shellcheck source=stats-lib.sh
  source "$STATS_PROMPTS_SCRIPT_DIR/stats-lib.sh"
fi
if ! declare -f stats_context_history &>/dev/null; then
  # shellcheck source=context-lib.sh
  source "$STATS_PROMPTS_SCRIPT_DIR/context-lib.sh"
fi

# Allow tests to override the settings file path
STATS_SETTINGS_FILE="${STATS_SETTINGS_FILE:-.pm/ccpm-settings.json}"

# ---------------------------------------------------------------------------
# stats_collect_prompts <type> <name>
#
# Collects user prompts for each context window of the given work item.
# Stores them in .pm/stats/{type}s/{name}/prompts/session-{started}.txt
#
# Reads collectPrompts from settings — returns silently if disabled.
# Idempotent: skips windows that already have a prompt file.
# ---------------------------------------------------------------------------
stats_collect_prompts() {
  local type="$1" name="$2"
  if [ -z "$type" ] || [ -z "$name" ]; then
    return 0
  fi

  # Check if prompt collection is enabled
  local collect="false"
  if [ -f "$STATS_SETTINGS_FILE" ]; then
    collect="$(jq -r '.collectPrompts // false' "$STATS_SETTINGS_FILE" 2>/dev/null)"
  fi
  if [ "$collect" != "true" ]; then
    return 0
  fi

  # Get context windows for this work item
  local history
  history="$(stats_context_history "$type" "$name")"
  local window_count
  window_count="$(echo "$history" | jq 'length')"

  if [ "$window_count" -eq 0 ] 2>/dev/null; then
    return 0
  fi

  local prompts_dir=".pm/stats/${type}s/${name}/prompts"
  mkdir -p "$prompts_dir" 2>/dev/null || true

  local i started ended safe_ts prompt_file
  for (( i = 0; i < window_count; i++ )); do
    started="$(echo "$history" | jq -r ".[$i].started")"
    ended="$(echo "$history" | jq -r ".[$i].ended")"

    # Build a filename-safe timestamp (replace : with -)
    safe_ts="${started//:/-}"
    prompt_file="${prompts_dir}/session-${safe_ts}.txt"

    # Skip if already collected (idempotent)
    if [ -f "$prompt_file" ]; then
      continue
    fi

    # Skip windows with no end timestamp
    if [ -z "$ended" ] || [ "$ended" = "null" ]; then
      continue
    fi

    # Extract prompts for this window
    local raw_prompts
    raw_prompts="$(stats_extract_prompts "$started" "$ended")"

    # Skip if no prompts found
    if [ -z "$raw_prompts" ]; then
      continue
    fi

    # Write the prompt file
    {
      echo "# Prompts for ${type}/${name} — Session ${started}"
      echo ""
      while IFS=$'\t' read -r ts text; do
        [ -z "$ts" ] && continue
        echo "## [${ts}]"
        echo "$text"
        echo ""
      done <<< "$raw_prompts"
    } > "$prompt_file"
  done
}
