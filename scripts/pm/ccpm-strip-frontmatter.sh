#!/bin/bash
# ccpm-strip-frontmatter.sh — Strips YAML frontmatter from a markdown file.
#
# Usage: bash scripts/pm/ccpm-strip-frontmatter.sh <input-file> [output-file]
#
# If output-file is given, writes cleaned content there.
# Otherwise, outputs to stdout.
# If the file has no frontmatter, passes content through unchanged.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: ccpm-strip-frontmatter.sh <input-file> [output-file]"
  exit 1
fi

input_file="$1"
output_file="${2:-}"

if [ ! -f "$input_file" ]; then
  echo "ERROR: File not found: $input_file"
  exit 1
fi

# Check if the file starts with a frontmatter delimiter
first_line=$(head -1 "$input_file")
if [ "$first_line" != "---" ]; then
  # No frontmatter — pass through unchanged
  if [ -n "$output_file" ]; then
    cp "$input_file" "$output_file"
  else
    cat "$input_file"
  fi
  exit 0
fi

# Strip frontmatter (everything between first two --- lines)
if [ -n "$output_file" ]; then
  sed '1,/^---$/d; 1,/^---$/d' "$input_file" > "$output_file"
else
  sed '1,/^---$/d; 1,/^---$/d' "$input_file"
fi

exit 0
