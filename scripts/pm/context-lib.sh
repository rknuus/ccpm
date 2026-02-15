#!/bin/bash
# context-lib.sh — Library for tracking active work item context with timestamped history.
# Source this file to get stats_context_* functions. No execution at source time.

# Path to the active context file (relative to project root)
# Allow callers (e.g., tests) to override before sourcing
STATS_CONTEXT_FILE="${STATS_CONTEXT_FILE:-.pm/stats/active-context.json}"

# Ensure the context file exists with a valid initial structure.
_stats_context_ensure_file() {
  local dir
  dir="$(dirname "$STATS_CONTEXT_FILE")"
  mkdir -p "$dir" 2>/dev/null || true
  if [ ! -f "$STATS_CONTEXT_FILE" ]; then
    printf '{"current":null,"history":[]}\n' > "$STATS_CONTEXT_FILE" 2>/dev/null || true
  fi
}

# Set the active context. If one is already open, close it first.
# Usage: stats_context_open <type> <name> <command>
#   type    — one of: prd, epic, task
#   name    — work item identifier
#   command — CCPM command name (e.g., prd-new)
stats_context_open() {
  local ctx_type="$1" ctx_name="$2" ctx_command="$3"
  if [ -z "$ctx_type" ] || [ -z "$ctx_name" ] || [ -z "$ctx_command" ]; then
    return 0
  fi

  _stats_context_ensure_file

  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # If there is already an active context, close it first
  local has_current
  has_current="$(jq -r '.current != null' "$STATS_CONTEXT_FILE" 2>/dev/null)"
  if [ "$has_current" = "true" ]; then
    jq --arg ended "$now" \
      '.history += [.current + {ended: $ended}] | .current = null' \
      "$STATS_CONTEXT_FILE" > "${STATS_CONTEXT_FILE}.tmp" 2>/dev/null \
      && mv "${STATS_CONTEXT_FILE}.tmp" "$STATS_CONTEXT_FILE" 2>/dev/null || true
  fi

  # Set the new active context
  jq --arg type "$ctx_type" \
     --arg name "$ctx_name" \
     --arg command "$ctx_command" \
     --arg started "$now" \
     '.current = {type: $type, name: $name, command: $command, started: $started}' \
     "$STATS_CONTEXT_FILE" > "${STATS_CONTEXT_FILE}.tmp" 2>/dev/null \
    && mv "${STATS_CONTEXT_FILE}.tmp" "$STATS_CONTEXT_FILE" 2>/dev/null || true
}

# Close the current active context by setting its end timestamp and moving it to history.
# If no active context, does nothing.
# Usage: stats_context_close
stats_context_close() {
  _stats_context_ensure_file

  local has_current
  has_current="$(jq -r '.current != null' "$STATS_CONTEXT_FILE" 2>/dev/null)"
  if [ "$has_current" != "true" ]; then
    return 0
  fi

  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  jq --arg ended "$now" \
    '.history += [.current + {ended: $ended}] | .current = null' \
    "$STATS_CONTEXT_FILE" > "${STATS_CONTEXT_FILE}.tmp" 2>/dev/null \
    && mv "${STATS_CONTEXT_FILE}.tmp" "$STATS_CONTEXT_FILE" 2>/dev/null || true
}

# Return a JSON array of history entries for a given work item (filtered by type and name).
# Usage: stats_context_history <type> <name>
# Output: JSON array to stdout
stats_context_history() {
  local ctx_type="$1" ctx_name="$2"
  if [ -z "$ctx_type" ] || [ -z "$ctx_name" ]; then
    echo "[]"
    return 0
  fi

  _stats_context_ensure_file

  jq --arg type "$ctx_type" --arg name "$ctx_name" \
    '[.history[] | select(.type == $type and .name == $name)]' \
    "$STATS_CONTEXT_FILE" 2>/dev/null || echo "[]"
}
