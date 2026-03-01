#!/bin/bash
#
# stats.sh — Helper script for /ccpm:stats and /ccpm:stats-show commands.
#
# Usage:
#   bash scripts/pm/stats.sh overview           — overview dashboard
#   bash scripts/pm/stats.sh show <type> <name>  — detailed view for one work item
#
# Requires: jq, stats-lib.sh, ccpm-context

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/stats-lib.sh"

CONTEXT_FILE=".pm/stats/active-context.json"
SETTINGS_FILE=".pm/ccpm-settings.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Format seconds as human-readable (e.g., "2h 15m", "45m", "30s")
fmt_duration() {
  local secs="$1"
  # Handle non-integer / empty
  secs="${secs%%.*}"
  secs="${secs:-0}"
  if [ "$secs" -lt 60 ]; then
    echo "${secs}s"
  elif [ "$secs" -lt 3600 ]; then
    local m=$((secs / 60))
    local s=$((secs % 60))
    if [ "$s" -eq 0 ]; then
      echo "${m}m"
    else
      echo "${m}m ${s}s"
    fi
  else
    local h=$((secs / 3600))
    local m=$(( (secs % 3600) / 60 ))
    if [ "$m" -eq 0 ]; then
      echo "${h}h"
    else
      echo "${h}h ${m}m"
    fi
  fi
}

# Format number with commas (e.g., 45000 -> 45,000)
fmt_number() {
  local n="$1"
  n="${n:-0}"
  # Use awk for portable comma formatting (works on macOS + Linux)
  printf "%d" "$n" 2>/dev/null | awk '{len=length($0); r=""; for(i=1;i<=len;i++){r=r substr($0,i,1); if((len-i)%3==0 && i!=len) r=r","} print r}'
}

# Get setting value from ccpm-settings.json
get_setting() {
  local key="$1" default="$2"
  if [ -f "$SETTINGS_FILE" ]; then
    local val
    val=$(jq -r --arg k "$key" 'if has($k) then .[$k] | tostring else empty end' "$SETTINGS_FILE" 2>/dev/null)
    echo "${val:-$default}"
  else
    echo "$default"
  fi
}

# Export idle threshold for stats_derive_time() (convert minutes → seconds)
_idle_minutes=$(get_setting "idleThresholdMinutes" "5")
export STATS_IDLE_THRESHOLD_SECS=$((_idle_minutes * 60))

# Get unique work items from active-context.json history
get_unique_items() {
  if [ ! -f "$CONTEXT_FILE" ]; then
    echo "[]"
    return 0
  fi
  jq '[.history[] | {type, name}] | unique' "$CONTEXT_FILE" 2>/dev/null || echo "[]"
}

# Compute stats for a single work item, return JSON
compute_item_stats() {
  local item_type="$1" item_name="$2"

  local history
  history=$("$SCRIPT_DIR/ccpm-context" history "$item_type" "$item_name")

  local session_count
  session_count=$(echo "$history" | jq 'length')

  if [ "$session_count" -eq 0 ]; then
    echo '{"total_tokens":0,"total_input":0,"total_output":0,"working_seconds":0,"waiting_seconds":0,"sessions":0,"by_model":{},"session_details":[]}'
    return 0
  fi

  # Accumulate stats across all context windows
  local total_input=0 total_output=0 total_cache_creation=0 total_cache_read=0
  local total_working=0 total_waiting=0
  local merged_models="{}"
  local session_details="[]"

  local i=0
  while [ "$i" -lt "$session_count" ]; do
    local entry
    entry=$(echo "$history" | jq ".[$i]")
    local started ended command
    started=$(echo "$entry" | jq -r '.started')
    ended=$(echo "$entry" | jq -r '.ended')
    command=$(echo "$entry" | jq -r '.command // "unknown"')

    # Filter files once per session, pass to both functions
    local filtered_files=()
    while IFS= read -r f; do
      filtered_files+=("$f")
    done < <(stats_filter_files_by_timerange "$started" "$ended")

    # Get tokens for this window
    local tokens_json
    if [ ${#filtered_files[@]} -gt 0 ]; then
      tokens_json=$(stats_sum_tokens "$started" "$ended" "${filtered_files[@]}")
    else
      tokens_json=$(stats_sum_tokens "$started" "$ended")
    fi

    local inp outp cc cr
    inp=$(echo "$tokens_json" | jq '.total.input // 0')
    outp=$(echo "$tokens_json" | jq '.total.output // 0')
    cc=$(echo "$tokens_json" | jq '.total.cache_creation // 0')
    cr=$(echo "$tokens_json" | jq '.total.cache_read // 0')

    total_input=$((total_input + inp))
    total_output=$((total_output + outp))
    total_cache_creation=$((total_cache_creation + cc))
    total_cache_read=$((total_cache_read + cr))

    # Merge by_model
    merged_models=$(echo "$merged_models" | jq --argjson new "$(echo "$tokens_json" | jq '.by_model')" '
      . as $old | $new | to_entries | reduce .[] as $e ($old;
        if .[$e.key] then
          .[$e.key].input += $e.value.input
          | .[$e.key].output += $e.value.output
          | .[$e.key].cache_creation += $e.value.cache_creation
          | .[$e.key].cache_read += $e.value.cache_read
        else
          .[$e.key] = $e.value
        end
      )')

    # Get time for this window
    local time_json
    if [ ${#filtered_files[@]} -gt 0 ]; then
      time_json=$(stats_derive_time "$started" "$ended" "${filtered_files[@]}")
    else
      time_json=$(stats_derive_time "$started" "$ended")
    fi

    local ws us
    ws=$(echo "$time_json" | jq '.claude_working_seconds // 0')
    us=$(echo "$time_json" | jq '.user_wait_seconds // 0')

    total_working=$((total_working + ws))
    total_waiting=$((total_waiting + us))

    # Build session detail
    local window_tokens=$((inp + outp + cc + cr))
    session_details=$(echo "$session_details" | jq --arg cmd "$command" \
      --arg s "$started" --arg e "$ended" \
      --argjson tok "$window_tokens" --argjson work "$ws" --argjson wait "$us" \
      '. + [{ command: $cmd, started: $s, ended: $e, tokens: $tok, working_seconds: $work, waiting_seconds: $wait }]')

    i=$((i + 1))
  done

  local total_tokens=$((total_input + total_output + total_cache_creation + total_cache_read))

  jq -n \
    --argjson tt "$total_tokens" \
    --argjson ti "$total_input" \
    --argjson to "$total_output" \
    --argjson tcc "$total_cache_creation" \
    --argjson tcr "$total_cache_read" \
    --argjson ws "$total_working" \
    --argjson us "$total_waiting" \
    --argjson sc "$session_count" \
    --argjson bm "$merged_models" \
    --argjson sd "$session_details" \
    '{
      total_tokens: $tt,
      total_input: $ti,
      total_output: $to,
      total_cache_creation: $tcc,
      total_cache_read: $tcr,
      working_seconds: $ws,
      waiting_seconds: $us,
      sessions: $sc,
      by_model: $bm,
      session_details: $sd
    }'
}

# Read satisfaction from stats.json for a work item
read_satisfaction() {
  local item_type="$1" item_name="$2"
  local file=".pm/stats/${item_type}s/${item_name}/stats.json"
  if [ -f "$file" ]; then
    jq '.satisfaction // {}' "$file" 2>/dev/null || echo "{}"
  else
    echo "{}"
  fi
}

# Get the best available rating string (immediate or delayed, prefer delayed)
fmt_rating() {
  local sat="$1"
  local delayed immediate
  delayed=$(echo "$sat" | jq -r '.delayed.rating // empty' 2>/dev/null)
  immediate=$(echo "$sat" | jq -r '.immediate.rating // empty' 2>/dev/null)
  if [ -n "$delayed" ]; then
    echo "${delayed}/5"
  elif [ -n "$immediate" ]; then
    echo "${immediate}/5"
  else
    echo "-"
  fi
}

# Cache version — increment when computation logic changes to invalidate old caches
STATS_CACHE_VERSION=2

# Cache stats to .pm/stats/{type}s/{name}/stats.json (merge with existing satisfaction)
cache_stats() {
  local item_type="$1" item_name="$2" computed_json="$3"
  local dir=".pm/stats/${item_type}s/${item_name}"
  local file="${dir}/stats.json"
  mkdir -p "$dir" 2>/dev/null || true

  local existing_sat="{}"
  if [ -f "$file" ]; then
    existing_sat=$(jq '.satisfaction // {}' "$file" 2>/dev/null || echo "{}")
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "$computed_json" | jq --argjson sat "$existing_sat" --arg ts "$now" \
    --argjson cv "$STATS_CACHE_VERSION" \
    '. + { satisfaction: $sat, computed_at: $ts, cache_version: $cv }' > "$file"
}

# Check if cache is still valid (no newer history entries than computed_at, correct version)
is_cache_valid() {
  local item_type="$1" item_name="$2"
  local file=".pm/stats/${item_type}s/${item_name}/stats.json"
  [ ! -f "$file" ] && return 1

  # Invalidate if cache version doesn't match
  local cached_version
  cached_version=$(jq -r '.cache_version // 0' "$file" 2>/dev/null)
  [ "$cached_version" != "$STATS_CACHE_VERSION" ] && return 1

  local computed_at
  computed_at=$(jq -r '.computed_at // empty' "$file" 2>/dev/null)
  [ -z "$computed_at" ] && return 1

  # Check if any history entry has ended after computed_at
  local newer
  newer=$("$SCRIPT_DIR/ccpm-context" history "$item_type" "$item_name" \
    | jq --arg ca "$computed_at" '[.[] | select(.ended > $ca)] | length')
  [ "$newer" -eq 0 ] && return 0
  return 1
}

# Load cached stats or return empty
load_cached_stats() {
  local item_type="$1" item_name="$2"
  local file=".pm/stats/${item_type}s/${item_name}/stats.json"
  if [ -f "$file" ]; then
    jq '.' "$file" 2>/dev/null
  else
    echo "{}"
  fi
}

# Start a background watchdog that kills this process after N seconds.
# Call _cancel_timeout when the command finishes normally.
_TIMEOUT_PID=""
_TIMEOUT_SECS=""
_start_timeout() {
  _TIMEOUT_SECS="$1"
  ( sleep "$_TIMEOUT_SECS"; kill -TERM $$ 2>/dev/null ) </dev/null >/dev/null 2>&1 &
  _TIMEOUT_PID=$!
  trap 'echo "" >&2; echo "❌ Stats computation timed out after ${_TIMEOUT_SECS}s. Cached results (if any) are still available." >&2; kill $_TIMEOUT_PID 2>/dev/null; exit 124' TERM
}
_cancel_timeout() {
  if [ -n "$_TIMEOUT_PID" ]; then
    kill "$_TIMEOUT_PID" 2>/dev/null || true
    wait "$_TIMEOUT_PID" 2>/dev/null || true
    _TIMEOUT_PID=""
  fi
}

# ---------------------------------------------------------------------------
# Command: overview
# ---------------------------------------------------------------------------
cmd_overview() {
  if [ ! -f "$CONTEXT_FILE" ]; then
    echo "No stats collected yet. Stats are tracked automatically when you use CCPM commands."
    exit 0
  fi

  # Auto-compress old JSONL files
  stats_compress_old_files >/dev/null 2>&1 || true

  local items
  items=$(get_unique_items)

  local count
  count=$(echo "$items" | jq 'length')

  if [ "$count" -eq 0 ]; then
    echo "No stats collected yet. Stats are tracked automatically when you use CCPM commands."
    exit 0
  fi

  local stats_timeout
  stats_timeout=$(get_setting "statsTimeout" "30")
  _start_timeout "$stats_timeout"

  # Compute stats for each item, collect raw numbers as JSON array
  local raw_data="[]"

  local i=0
  while [ "$i" -lt "$count" ]; do
    local item_type item_name
    item_type=$(echo "$items" | jq -r ".[$i].type")
    item_name=$(echo "$items" | jq -r ".[$i].name")

    echo -ne "\rComputing stats... $((i + 1))/$count items" >&2

    local stats
    if is_cache_valid "$item_type" "$item_name"; then
      stats=$(load_cached_stats "$item_type" "$item_name")
    else
      stats=$(compute_item_stats "$item_type" "$item_name")
      cache_stats "$item_type" "$item_name" "$stats"
    fi

    local tokens working waiting
    tokens=$(echo "$stats" | jq '.total_tokens // 0')
    working=$(echo "$stats" | jq '.working_seconds // 0')
    waiting=$(echo "$stats" | jq '.waiting_seconds // 0')

    raw_data=$(echo "$raw_data" | jq --arg t "$item_type" --arg n "$item_name" \
      --argjson tok "$tokens" --argjson w "$working" --argjson u "$waiting" \
      '. + [{type: $t, name: $n, tokens: $tok, working: $w, waiting: $u}]')

    i=$((i + 1))
  done

  # Clear progress line and cancel timeout
  echo -ne "\r\033[K" >&2
  _cancel_timeout

  # Merge rows by name: sum stats, pick best type (prefer epic over prd)
  local merged
  merged=$(echo "$raw_data" | jq '
    group_by(.name)
    | map({
        name: .[0].name,
        type: (if any(.type == "epic") then "epic" else .[0].type end),
        tokens: (map(.tokens) | add),
        working: (map(.working) | add),
        waiting: (map(.waiting) | add)
      })
    | sort_by(.name)')

  local merged_count
  merged_count=$(echo "$merged" | jq 'length')

  # Compute dynamic name width (min 20, max 50)
  local name_width=20
  local longest
  longest=$(echo "$merged" | jq '[.[] | .name | length] | max // 20')
  name_width=$((longest > 50 ? 50 : (longest < 20 ? 20 : longest)))

  # Build format strings
  local hdr_fmt="%-5s | %-${name_width}s | %11s | %8s | %8s\n"
  local sep_name
  sep_name=$(printf '%*s' "$name_width" '' | tr ' ' '-')
  local sep_fmt="%-5s-+-%-${name_width}s-+-%11s-+-%8s-+-%8s\n"

  # Print header
  printf "$hdr_fmt" "Type" "Name" "Tokens" "Working" "Waiting"
  printf "$sep_fmt" "-----" "$sep_name" "-----------" "--------" "--------"

  # Print rows
  local grand_tokens=0 grand_working=0 grand_waiting=0
  local j=0
  while [ "$j" -lt "$merged_count" ]; do
    local rtype rname rtok rwork rwait
    rtype=$(echo "$merged" | jq -r ".[$j].type")
    rname=$(echo "$merged" | jq -r ".[$j].name")
    rtok=$(echo "$merged" | jq ".[$j].tokens")
    rwork=$(echo "$merged" | jq ".[$j].working")
    rwait=$(echo "$merged" | jq ".[$j].waiting")

    # Truncate name if needed
    local dname="$rname"
    if [ ${#dname} -gt "$name_width" ]; then
      dname="${dname:0:$((name_width - 3))}..."
    fi

    printf "$hdr_fmt" "$rtype" "$dname" "$(fmt_number "$rtok")" \
      "$(fmt_duration "$rwork")" "$(fmt_duration "$rwait")"

    grand_tokens=$((grand_tokens + rtok))
    grand_working=$((grand_working + rwork))
    grand_waiting=$((grand_waiting + rwait))

    j=$((j + 1))
  done

  # Totals
  printf "$sep_fmt" "-----" "$sep_name" "-----------" "--------" "--------"
  printf "$hdr_fmt" "TOTAL" "" "$(fmt_number "$grand_tokens")" \
    "$(fmt_duration "$grand_working")" "$(fmt_duration "$grand_waiting")"
}

# ---------------------------------------------------------------------------
# Command: show <type> <name>
# ---------------------------------------------------------------------------
cmd_show() {
  local item_type="${1:-}" item_name="${2:-}"

  if [ -z "$item_type" ] || [ -z "$item_name" ]; then
    echo "Usage: /ccpm:stats-show <type> <name>"
    echo "  type: prd, epic, or task"
    echo "  name: work item name or issue number"
    exit 1
  fi

  case "$item_type" in
    prd|epic|task) ;;
    *)
      echo "Invalid type: $item_type (must be prd, epic, or task)"
      exit 1
      ;;
  esac

  # Auto-compress old JSONL files
  stats_compress_old_files >/dev/null 2>&1 || true

  local stats_timeout
  stats_timeout=$(get_setting "statsTimeout" "30")
  _start_timeout "$stats_timeout"

  # Compute or load cached stats
  local stats
  if is_cache_valid "$item_type" "$item_name"; then
    stats=$(load_cached_stats "$item_type" "$item_name")
  else
    stats=$(compute_item_stats "$item_type" "$item_name")
    cache_stats "$item_type" "$item_name" "$stats"
  fi

  _cancel_timeout

  local sessions
  sessions=$(echo "$stats" | jq '.sessions // 0')

  if [ "$sessions" -eq 0 ]; then
    echo "No stats found for $item_type '$item_name'."
    echo ""
    echo "Stats are tracked automatically when you use CCPM commands."
    echo "Make sure context tracking is enabled for this work item."
    exit 0
  fi

  # --- Summary ---
  local total_tokens total_input total_output total_cc total_cr working waiting
  total_tokens=$(echo "$stats" | jq '.total_tokens // 0')
  total_input=$(echo "$stats" | jq '.total_input // 0')
  total_output=$(echo "$stats" | jq '.total_output // 0')
  total_cc=$(echo "$stats" | jq '.total_cache_creation // 0')
  total_cr=$(echo "$stats" | jq '.total_cache_read // 0')
  working=$(echo "$stats" | jq '.working_seconds // 0')
  waiting=$(echo "$stats" | jq '.waiting_seconds // 0')

  local sat rating_str
  sat=$(read_satisfaction "$item_type" "$item_name")
  rating_str=$(fmt_rating "$sat")

  echo "Stats: $item_type / $item_name"
  echo "========================================"
  echo ""
  echo "Summary"
  echo "--------"
  echo "  Total tokens:   $(fmt_number "$total_tokens")"
  echo "    Input:         $(fmt_number "$total_input")"
  echo "    Output:        $(fmt_number "$total_output")"
  echo "    Cache create:  $(fmt_number "$total_cc")"
  echo "    Cache read:    $(fmt_number "$total_cr")"
  echo "  Working time:   $(fmt_duration "$working")"
  echo "  Waiting time:   $(fmt_duration "$waiting")"
  echo "  Sessions:       $sessions"
  echo "  Satisfaction:   $rating_str"

  # Show satisfaction details if available
  local imm_rating del_rating
  imm_rating=$(echo "$sat" | jq -r '.immediate.rating // empty' 2>/dev/null)
  del_rating=$(echo "$sat" | jq -r '.delayed.rating // empty' 2>/dev/null)
  if [ -n "$imm_rating" ]; then
    local imm_ts
    imm_ts=$(echo "$sat" | jq -r '.immediate.timestamp // ""')
    echo "    Immediate:    ${imm_rating}/5 ($imm_ts)"
  fi
  if [ -n "$del_rating" ]; then
    local del_ts del_note
    del_ts=$(echo "$sat" | jq -r '.delayed.timestamp // ""')
    del_note=$(echo "$sat" | jq -r '.delayed.note // empty' 2>/dev/null)
    echo "    Delayed:      ${del_rating}/5 ($del_ts)"
    [ -n "$del_note" ] && echo "                  Note: \"$del_note\""
  fi

  # --- Sessions ---
  echo ""
  echo "Sessions"
  echo "--------"
  local sd_count
  sd_count=$(echo "$stats" | jq '.session_details | length')
  printf "  %-3s  %-14s  %-20s  %-20s  %9s  %8s\n" "#" "Command" "Started" "Ended" "Tokens" "Working"
  printf "  %-3s  %-14s  %-20s  %-20s  %9s  %8s\n" "---" "--------------" "--------------------" "--------------------" "---------" "--------"

  local j=0
  while [ "$j" -lt "$sd_count" ]; do
    local sd
    sd=$(echo "$stats" | jq ".session_details[$j]")
    local scmd sstart send stok swork
    scmd=$(echo "$sd" | jq -r '.command')
    sstart=$(echo "$sd" | jq -r '.started')
    send=$(echo "$sd" | jq -r '.ended')
    stok=$(echo "$sd" | jq '.tokens')
    swork=$(echo "$sd" | jq '.working_seconds')

    # Truncate command name to 14 chars
    local dcmd="$scmd"
    [ ${#dcmd} -gt 14 ] && dcmd="${dcmd:0:11}..."

    printf "  %-3s  %-14s  %-20s  %-20s  %9s  %8s\n" \
      "$((j + 1))" "$dcmd" "$sstart" "$send" "$(fmt_number "$stok")" "$(fmt_duration "$swork")"

    j=$((j + 1))
  done

  # --- Model Breakdown ---
  echo ""
  echo "Model Breakdown"
  echo "--------"
  local model_keys
  model_keys=$(echo "$stats" | jq -r '.by_model | keys[]' 2>/dev/null)

  if [ -n "$model_keys" ]; then
    printf "  %-30s  %9s  %9s  %9s  %9s\n" "Model" "Input" "Output" "CacheW" "CacheR"
    printf "  %-30s  %9s  %9s  %9s  %9s\n" "------------------------------" "---------" "---------" "---------" "---------"

    echo "$model_keys" | while IFS= read -r model; do
      local mi mo mcc mcr
      mi=$(echo "$stats" | jq --arg m "$model" '.by_model[$m].input // 0')
      mo=$(echo "$stats" | jq --arg m "$model" '.by_model[$m].output // 0')
      mcc=$(echo "$stats" | jq --arg m "$model" '.by_model[$m].cache_creation // 0')
      mcr=$(echo "$stats" | jq --arg m "$model" '.by_model[$m].cache_read // 0')

      # Truncate model name
      local dmodel="$model"
      [ ${#dmodel} -gt 30 ] && dmodel="${dmodel:0:27}..."

      printf "  %-30s  %9s  %9s  %9s  %9s\n" \
        "$dmodel" "$(fmt_number "$mi")" "$(fmt_number "$mo")" "$(fmt_number "$mcc")" "$(fmt_number "$mcr")"
    done
  else
    echo "  No model data available."
  fi

  # --- Time Analysis ---
  echo ""
  echo "Time Analysis"
  echo "--------"
  local total_time=$((working + waiting))
  if [ "$total_time" -gt 0 ]; then
    local work_pct=$((working * 100 / total_time))
    local wait_pct=$((100 - work_pct))
    echo "  Total time:       $(fmt_duration "$total_time")"
    echo "  Working (Claude):  $(fmt_duration "$working") (${work_pct}%)"
    echo "  Waiting (user):    $(fmt_duration "$waiting") (${wait_pct}%)"
  else
    echo "  Total time:       0s"
    echo "  Working (Claude):  0s"
    echo "  Waiting (user):    0s"
  fi
  if [ "$sessions" -gt 0 ]; then
    local avg_work=$((working / sessions))
    local avg_wait=$((waiting / sessions))
    local avg_tok=$((total_tokens / sessions))
    echo "  Avg per session:"
    echo "    Working:  $(fmt_duration "$avg_work")"
    echo "    Waiting:  $(fmt_duration "$avg_wait")"
    echo "    Tokens:   $(fmt_number "$avg_tok")"
  fi

  # --- Prompts ---
  echo ""
  echo "Prompts"
  echo "--------"
  local collect_prompts
  collect_prompts=$(get_setting "collectPrompts" "false")

  local prompt_dir=".pm/stats/${item_type}s/${item_name}/prompts"
  local prompt_count=0
  if [ -d "$prompt_dir" ]; then
    prompt_count=$(find "$prompt_dir" -name '*.txt' -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  if [ "$collect_prompts" = "true" ]; then
    echo "  Prompt collection: enabled"
    echo "  Stored prompts:    $prompt_count"
    if [ "$prompt_count" -gt 0 ]; then
      echo "  Files:"
      find "$prompt_dir" -name '*.txt' -type f 2>/dev/null | sort | while IFS= read -r pf; do
        echo "    $(basename "$pf")"
      done
    fi
  else
    echo "  Prompt collection: disabled"
    echo "  Enable with: /ccpm:config collectPrompts true"
  fi

  # --- Actions ---
  echo ""
  echo "Actions"
  echo "--------"
  echo "  Rate satisfaction: /ccpm:stats-rate $item_type $item_name"
  echo "  Overview:          /ccpm:stats"
}

# ---------------------------------------------------------------------------
# Command: compress
# ---------------------------------------------------------------------------
cmd_compress() {
  echo "Compressing old JSONL session files..."
  echo ""
  stats_compress_old_files "${1:-7}"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
main() {
  local subcmd="${1:-}"
  shift || true

  case "$subcmd" in
    overview)
      cmd_overview
      ;;
    show)
      cmd_show "$@"
      ;;
    compress)
      cmd_compress "$@"
      ;;
    *)
      echo "Usage:"
      echo "  bash scripts/pm/stats.sh overview"
      echo "  bash scripts/pm/stats.sh show <type> <name>"
      exit 1
      ;;
  esac
}

main "$@"
