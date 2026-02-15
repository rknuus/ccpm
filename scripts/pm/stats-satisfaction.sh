#!/bin/bash
#
# stats-satisfaction.sh - Satisfaction rating helpers for CCPM stats
#
# Usage:
#   source scripts/pm/stats-satisfaction.sh
#   stats_save_rating <type> <name> <rating_type> <rating> [note]
#
# Arguments:
#   type        - prd, epic, or task
#   name        - work item name or issue number
#   rating_type - immediate or delayed
#   rating      - 1-5
#   note        - optional text note (for delayed ratings)

stats_save_rating() {
  local type="$1"
  local name="$2"
  local rating_type="$3"
  local rating="$4"
  local note="$5"

  # Validate arguments
  if [ -z "$type" ] || [ -z "$name" ] || [ -z "$rating_type" ] || [ -z "$rating" ]; then
    echo "Usage: stats_save_rating <type> <name> <rating_type> <rating> [note]"
    return 1
  fi

  # Validate type
  case "$type" in
    prd|epic|task) ;;
    *)
      echo "Invalid type: $type (must be prd, epic, or task)"
      return 1
      ;;
  esac

  # Validate rating_type
  case "$rating_type" in
    immediate|delayed) ;;
    *)
      echo "Invalid rating_type: $rating_type (must be immediate or delayed)"
      return 1
      ;;
  esac

  # Validate rating is 1-5
  if ! echo "$rating" | grep -qE '^[1-5]$'; then
    echo "Invalid rating: $rating (must be 1-5)"
    return 1
  fi

  # Check jq is available
  if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Install: brew install jq (macOS) or apt install jq (Linux)"
    return 1
  fi

  # Determine directory (pluralize type for directory name)
  local dir=".pm/stats/${type}s/${name}"
  local file="${dir}/stats.json"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Create directory if needed
  mkdir -p "$dir"

  # Build the rating object
  local rating_obj
  if [ "$rating_type" = "delayed" ] && [ -n "$note" ]; then
    rating_obj=$(jq -n --argjson r "$rating" --arg t "$timestamp" --arg n "$note" \
      '{ rating: $r, timestamp: $t, note: $n }')
  else
    rating_obj=$(jq -n --argjson r "$rating" --arg t "$timestamp" \
      '{ rating: $r, timestamp: $t }')
  fi

  # Create or merge into stats.json
  if [ -f "$file" ]; then
    # Merge satisfaction field into existing file
    local existing
    existing=$(cat "$file")
    echo "$existing" | jq --argjson obj "$rating_obj" --arg rt "$rating_type" \
      '.satisfaction[$rt] = $obj' > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    # Create new stats.json with satisfaction field
    jq -n --argjson obj "$rating_obj" --arg rt "$rating_type" \
      '{ satisfaction: { ($rt): $obj } }' > "$file"
  fi

  echo "Saved ${rating_type} rating (${rating}/5) to ${file}"
}
