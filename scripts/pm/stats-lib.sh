#!/bin/bash
# stats-lib.sh — Reusable functions for parsing Claude Code JSONL session logs.
# Source this file; do not execute directly.
#
# All functions use the stats_ prefix for namespacing.
# Requires: jq

# ---------------------------------------------------------------------------
# stats_find_jsonl_files
#
# Discovers top-level JSONL session files for the current project under
# ~/.claude/projects/ (falls back to ~/.config/claude/projects/).
#
# Subagent JSONL files (under */subagents/*.jsonl) are excluded because
# parent session entries already aggregate subagent token usage.
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

  # Top-level session JSONL files only (excludes subagent files)
  find "$base_dir" -maxdepth 1 \( -name '*.jsonl' -o -name '*.jsonl.gz' \) -type f 2>/dev/null
}

# ---------------------------------------------------------------------------
# stats_cat_files FILE...
#
# Outputs the contents of the given files to stdout, transparently
# decompressing any .gz files. Equivalent to cat for plain files.
# ---------------------------------------------------------------------------
stats_cat_files() {
  local file
  for file in "$@"; do
    [ -f "$file" ] || continue
    case "$file" in
      *.gz) gzip -dc "$file" 2>/dev/null ;;
      *)    cat "$file" 2>/dev/null ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# stats_filter_files_by_timerange START END [FILES...]
#
# Filters JSONL files to only those whose modification time >= START epoch.
# This safely over-includes (never misses relevant files) since a file
# modified before START cannot contain entries timestamped >= START.
#
# If FILES are not provided, discovers files via stats_find_jsonl_files.
# Outputs one file path per line (same format as stats_find_jsonl_files).
# ---------------------------------------------------------------------------
stats_filter_files_by_timerange() {
  local start="$1" end="$2"
  shift 2

  # Convert START ISO 8601 to epoch seconds (strip milliseconds first)
  local clean_start
  clean_start="${start%%.*Z}"
  # Re-append Z if milliseconds were stripped; pass through if no milliseconds
  [[ "$start" == *.*Z ]] && clean_start="${clean_start}Z"
  local start_epoch
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_start" +%s &>/dev/null; then
    start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clean_start" +%s 2>/dev/null)
  else
    start_epoch=$(date -d "$clean_start" +%s 2>/dev/null)
  fi
  # If conversion failed, return all files (safe fallback)
  if [ -z "$start_epoch" ]; then
    if [ $# -gt 0 ]; then
      printf '%s\n' "$@"
    else
      stats_find_jsonl_files
    fi
    return 0
  fi

  local files=()
  if [ $# -gt 0 ]; then
    files=("$@")
  else
    while IFS= read -r f; do
      files+=("$f")
    done < <(stats_find_jsonl_files)
  fi

  # Detect stat flavor once
  local stat_cmd
  if stat -f %m /dev/null &>/dev/null 2>&1; then
    stat_cmd="macos"
  else
    stat_cmd="linux"
  fi

  [ ${#files[@]} -eq 0 ] && return 0

  local file mtime
  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    if [ "$stat_cmd" = "macos" ]; then
      mtime=$(stat -f %m "$file" 2>/dev/null) || continue
    else
      mtime=$(stat -c %Y "$file" 2>/dev/null) || continue
    fi
    if [ "$mtime" -ge "$start_epoch" ]; then
      echo "$file"
    fi
  done
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
    done < <(stats_filter_files_by_timerange "$start" "$end")
  fi

  [ ${#files[@]} -eq 0 ] && echo '{"total":{"input":0,"output":0,"cache_creation":0,"cache_read":0},"by_model":{}}' && return 0

  stats_cat_files "${files[@]}" \
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
# - Gaps exceeding STATS_IDLE_THRESHOLD_SECS (default 300 = 5 minutes) are
#   excluded as idle time (laptop sleep, overnight gaps, etc.).
#
# Returns JSON: {"claude_working_seconds": N, "user_wait_seconds": N}
# ---------------------------------------------------------------------------
stats_derive_time() {
  local start="$1" end="$2"
  shift 2

  local idle_threshold="${STATS_IDLE_THRESHOLD_SECS:-300}"

  local files=()
  if [ $# -gt 0 ]; then
    files=("$@")
  else
    while IFS= read -r f; do
      files+=("$f")
    done < <(stats_filter_files_by_timerange "$start" "$end")
  fi

  [ ${#files[@]} -eq 0 ] && echo '{"claude_working_seconds":0,"user_wait_seconds":0}' && return 0

  stats_cat_files "${files[@]}" \
    | jq -c --arg start "$start" --arg end "$end" '
        select((.type == "user" or .type == "assistant")
               and .timestamp >= $start
               and .timestamp <= $end)
        | {type, timestamp}' \
    | jq -s --argjson threshold "$idle_threshold" '
        # Helper: strip milliseconds so fromdateiso8601 works
        def to_epoch: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
        sort_by(.timestamp) as $msgs
        | reduce range(1; $msgs | length) as $i (
            {claude_working_seconds: 0, user_wait_seconds: 0};
            (($msgs[$i].timestamp | to_epoch) - ($msgs[$i-1].timestamp | to_epoch)) as $gap
            | if $gap > $threshold then .  # Skip idle gap
              elif $msgs[$i-1].type == "user" and $msgs[$i].type == "assistant" then
                .claude_working_seconds += $gap
              elif $msgs[$i-1].type == "assistant" and $msgs[$i].type == "user" then
                .user_wait_seconds += $gap
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
    done < <(stats_filter_files_by_timerange "$start" "$end")
  fi

  [ ${#files[@]} -eq 0 ] && return 0

  stats_cat_files "${files[@]}" \
    | jq -r --arg start "$start" --arg end "$end" '
        select(.type == "user"
               and .timestamp >= $start
               and .timestamp <= $end
               and (.message.content | type) == "string")
        | "\(.timestamp)\t\(.message.content)"'
}

# ---------------------------------------------------------------------------
# stats_compress_old_files [MAX_AGE_DAYS]
#
# Gzips JSONL session files that have not been modified in the last
# MAX_AGE_DAYS days (default: 7). The most recently modified .jsonl file
# is always excluded (likely the active session).
#
# Only operates on .jsonl files — already-compressed .jsonl.gz are skipped.
# Prints one line per compressed file to stdout.
# Returns the number of files compressed via exit code (0 = none or success).
# ---------------------------------------------------------------------------
stats_compress_old_files() {
  local max_age_days="${1:-7}"

  local project_root
  project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  local dir_name="${project_root//\//-}"

  local base_dir=""
  if [ -d "$HOME/.claude/projects/$dir_name" ]; then
    base_dir="$HOME/.claude/projects/$dir_name"
  elif [ -d "$HOME/.config/claude/projects/$dir_name" ]; then
    base_dir="$HOME/.config/claude/projects/$dir_name"
  else
    return 0
  fi

  # Find only uncompressed .jsonl files (not .jsonl.gz)
  local all_jsonl=()
  while IFS= read -r f; do
    all_jsonl+=("$f")
  done < <(find "$base_dir" -maxdepth 1 -name '*.jsonl' -type f 2>/dev/null | sort)

  [ ${#all_jsonl[@]} -le 1 ] && return 0  # Nothing to compress (0 or 1 file)

  # Find the newest file by mtime — exclude it from compression
  local newest=""
  local newest_mtime=0
  local stat_cmd
  if stat -f %m /dev/null &>/dev/null 2>&1; then
    stat_cmd="macos"
  else
    stat_cmd="linux"
  fi

  local file mtime
  for file in "${all_jsonl[@]}"; do
    if [ "$stat_cmd" = "macos" ]; then
      mtime=$(stat -f %m "$file" 2>/dev/null) || continue
    else
      mtime=$(stat -c %Y "$file" 2>/dev/null) || continue
    fi
    if [ "$mtime" -gt "$newest_mtime" ]; then
      newest_mtime="$mtime"
      newest="$file"
    fi
  done

  # Compute age threshold in epoch seconds
  local now threshold
  now=$(date +%s)
  threshold=$((now - max_age_days * 86400))

  local compressed=0
  local bytes_saved=0
  for file in "${all_jsonl[@]}"; do
    [ "$file" = "$newest" ] && continue  # Skip newest file

    if [ "$stat_cmd" = "macos" ]; then
      mtime=$(stat -f %m "$file" 2>/dev/null) || continue
    else
      mtime=$(stat -c %Y "$file" 2>/dev/null) || continue
    fi

    [ "$mtime" -ge "$threshold" ] && continue  # Not old enough

    local size_before
    if [ "$stat_cmd" = "macos" ]; then
      size_before=$(stat -f %z "$file" 2>/dev/null) || continue
    else
      size_before=$(stat -c %s "$file" 2>/dev/null) || continue
    fi

    if gzip "$file" 2>/dev/null; then
      local size_after
      if [ "$stat_cmd" = "macos" ]; then
        size_after=$(stat -f %z "${file}.gz" 2>/dev/null) || size_after=0
      else
        size_after=$(stat -c %s "${file}.gz" 2>/dev/null) || size_after=0
      fi
      bytes_saved=$((bytes_saved + size_before - size_after))
      compressed=$((compressed + 1))
      echo "Compressed: $(basename "$file") ($(( (size_before - size_after) / 1024 ))KB saved)"
    fi
  done

  if [ "$compressed" -gt 0 ]; then
    echo "Total: $compressed files compressed, $((bytes_saved / 1024))KB saved"
  fi
}
