#!/bin/bash
# stats-lib.sh — Reusable functions for parsing Claude Code JSONL session logs.
# Source this file; do not execute directly.
#
# All functions use the stats_ prefix for namespacing.
# Requires: jq

# ---------------------------------------------------------------------------
# stats_find_jsonl_files
#
# Discovers all JSONL files (including subagent logs) for the current project
# under ~/.claude/projects/ (falls back to ~/.config/claude/projects/).
#
# The directory name is the project's absolute path with "/" replaced by "-".
# e.g. /Users/rkn/Personal/FOSS/ccpm-fork -> -Users-rkn-Personal-FOSS-ccpm-fork
#
# Outputs one absolute file path per line.
# ---------------------------------------------------------------------------
stats_find_jsonl_files() {
  local project_root
  project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  # Build the directory name: replace / with -
  local dir_name
  dir_name="${project_root//\//-}"

  local base_dir=""
  if [ -d "$HOME/.claude/projects/$dir_name" ]; then
    base_dir="$HOME/.claude/projects/$dir_name"
  elif [ -d "$HOME/.config/claude/projects/$dir_name" ]; then
    base_dir="$HOME/.config/claude/projects/$dir_name"
  else
    return 0
  fi

  # Top-level session JSONL files
  find "$base_dir" -maxdepth 1 -name '*.jsonl' -type f 2>/dev/null

  # Subagent JSONL files inside {session}/subagents/
  find "$base_dir" -path '*/subagents/*.jsonl' -type f 2>/dev/null
}

# ---------------------------------------------------------------------------
# stats_sum_tokens START END [FILES...]
#
# Sums per-message token counts from assistant entries whose timestamp falls
# within [START, END] (inclusive, ISO 8601). Groups totals by model.
#
# If FILES are not provided, calls stats_find_jsonl_files.
#
# Returns JSON on stdout:
# {
#   "total": {"input": N, "output": N, "cache_creation": N, "cache_read": N},
#   "by_model": {"model-name": {"input": N, "output": N, ...}, ...}
# }
# ---------------------------------------------------------------------------
stats_sum_tokens() {
  local start="$1" end="$2"
  shift 2

  local files=()
  if [ $# -gt 0 ]; then
    files=("$@")
  else
    while IFS= read -r f; do
      files+=("$f")
    done < <(stats_find_jsonl_files)
  fi

  [ ${#files[@]} -eq 0 ] && echo '{"total":{"input":0,"output":0,"cache_creation":0,"cache_read":0},"by_model":{}}' && return 0

  cat "${files[@]}" 2>/dev/null \
    | jq -c --arg start "$start" --arg end "$end" '
        select(.type == "assistant"
               and .timestamp >= $start
               and .timestamp <= $end
               and .message.usage != null)
        | {
            model: (.message.model // "unknown"),
            input: (.message.usage.input_tokens // 0),
            output: (.message.usage.output_tokens // 0),
            cache_creation: (.message.usage.cache_creation_input_tokens // 0),
            cache_read: (.message.usage.cache_read_input_tokens // 0)
          }' \
    | jq -s '
        {
          total: {
            input: (map(.input) | add // 0),
            output: (map(.output) | add // 0),
            cache_creation: (map(.cache_creation) | add // 0),
            cache_read: (map(.cache_read) | add // 0)
          },
          by_model: (
            group_by(.model)
            | map({
                key: .[0].model,
                value: {
                  input: (map(.input) | add // 0),
                  output: (map(.output) | add // 0),
                  cache_creation: (map(.cache_creation) | add // 0),
                  cache_read: (map(.cache_read) | add // 0)
                }
              })
            | from_entries
          )
        }'
}

# ---------------------------------------------------------------------------
# stats_derive_time START END [FILES...]
#
# Computes Claude working time and user wait time within [START, END].
#
# - Claude working time: sum of gaps between each user message and the next
#   assistant response.
# - User wait time: sum of gaps between each assistant response and the next
#   user message.
#
# Returns JSON: {"claude_working_seconds": N, "user_wait_seconds": N}
# ---------------------------------------------------------------------------
stats_derive_time() {
  local start="$1" end="$2"
  shift 2

  local files=()
  if [ $# -gt 0 ]; then
    files=("$@")
  else
    while IFS= read -r f; do
      files+=("$f")
    done < <(stats_find_jsonl_files)
  fi

  [ ${#files[@]} -eq 0 ] && echo '{"claude_working_seconds":0,"user_wait_seconds":0}' && return 0

  cat "${files[@]}" 2>/dev/null \
    | jq -c --arg start "$start" --arg end "$end" '
        select((.type == "user" or .type == "assistant")
               and .timestamp >= $start
               and .timestamp <= $end)
        | {type, timestamp}' \
    | jq -s '
        # Helper: strip milliseconds so fromdateiso8601 works
        def to_epoch: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
        sort_by(.timestamp) as $msgs
        | reduce range(1; $msgs | length) as $i (
            {claude_working_seconds: 0, user_wait_seconds: 0};
            if $msgs[$i-1].type == "user" and $msgs[$i].type == "assistant" then
              .claude_working_seconds += (
                ($msgs[$i].timestamp | to_epoch) - ($msgs[$i-1].timestamp | to_epoch)
              )
            elif $msgs[$i-1].type == "assistant" and $msgs[$i].type == "user" then
              .user_wait_seconds += (
                ($msgs[$i].timestamp | to_epoch) - ($msgs[$i-1].timestamp | to_epoch)
              )
            else . end
          )'
}

# ---------------------------------------------------------------------------
# stats_extract_prompts START END [FILES...]
#
# Extracts user message text (entries where type == "user" and
# message.content is a string — arrays are tool results).
#
# Outputs one line per prompt: TIMESTAMP<TAB>TEXT
# ---------------------------------------------------------------------------
stats_extract_prompts() {
  local start="$1" end="$2"
  shift 2

  local files=()
  if [ $# -gt 0 ]; then
    files=("$@")
  else
    while IFS= read -r f; do
      files+=("$f")
    done < <(stats_find_jsonl_files)
  fi

  [ ${#files[@]} -eq 0 ] && return 0

  cat "${files[@]}" 2>/dev/null \
    | jq -r --arg start "$start" --arg end "$end" '
        select(.type == "user"
               and .timestamp >= $start
               and .timestamp <= $end
               and (.message.content | type) == "string")
        | "\(.timestamp)\t\(.message.content)"'
}
