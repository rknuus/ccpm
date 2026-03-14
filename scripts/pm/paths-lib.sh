#!/bin/bash
# paths-lib.sh — Reusable functions for resolving .pm/ directory paths.
# Source this file; do not execute directly.
#
# All functions use the pm_ prefix for namespacing.
# Functions echo paths only — no side effects (no mkdir, no file creation).

# ---------------------------------------------------------------------------
# pm_initiative_file <name>
#
# Returns the path to an initiative's markdown file.
# Example: pm_initiative_file "auth" → .pm/initiatives/auth.md
# ---------------------------------------------------------------------------
pm_initiative_file() {
  local name="$1"
  echo ".pm/initiatives/${name}.md"
}

# ---------------------------------------------------------------------------
# pm_initiative_dir <name>
#
# Returns the path to an initiative's directory.
# Example: pm_initiative_dir "auth" → .pm/initiatives/auth/
# ---------------------------------------------------------------------------
pm_initiative_dir() {
  local name="$1"
  echo ".pm/initiatives/${name}/"
}

# ---------------------------------------------------------------------------
# pm_epic_dir <initiative> <epic>
#
# Returns the path to an epic's directory under an initiative.
# Example: pm_epic_dir "auth" "login-flow" → .pm/initiatives/auth/login-flow/
# ---------------------------------------------------------------------------
pm_epic_dir() {
  local initiative="$1"
  local epic="$2"
  echo ".pm/initiatives/${initiative}/${epic}/"
}

# ---------------------------------------------------------------------------
# pm_epic_file <initiative> <epic>
#
# Returns the path to an epic's markdown file under an initiative.
# Example: pm_epic_file "auth" "login-flow" → .pm/initiatives/auth/login-flow/epic.md
# ---------------------------------------------------------------------------
pm_epic_file() {
  local initiative="$1"
  local epic="$2"
  echo ".pm/initiatives/${initiative}/${epic}/epic.md"
}

# ---------------------------------------------------------------------------
# pm_task_file <initiative> <epic> <id>
#
# Returns the path to a task file under an epic.
# Example: pm_task_file "auth" "login-flow" "42" → .pm/initiatives/auth/login-flow/42.md
# ---------------------------------------------------------------------------
pm_task_file() {
  local initiative="$1"
  local epic="$2"
  local id="$3"
  echo ".pm/initiatives/${initiative}/${epic}/${id}.md"
}

# ---------------------------------------------------------------------------
# pm_find_epic <epic>
#
# Resolves the location of an epic directory by searching both the new
# nested layout (.pm/initiatives/*/<epic>/) and the old flat layout
# (.pm/epics/<epic>/). Prefers the new layout when both exist.
#
# Returns:
#   - New-layout directory if .pm/initiatives/*/<epic>/epic.md exists
#   - Old-layout directory if .pm/epics/<epic>/ exists (fallback)
#   - New-layout default path for creation if neither exists
# ---------------------------------------------------------------------------
pm_find_epic() {
  local epic="$1"

  # Check new layout: .pm/initiatives/*/<epic>/epic.md
  local match
  for match in .pm/initiatives/*/"${epic}"/epic.md; do
    if [ -f "$match" ]; then
      # Strip /epic.md to return the directory
      echo "${match%/epic.md}/"
      return 0
    fi
  done

  # Fallback: old layout .pm/epics/<epic>/
  if [ -d ".pm/epics/${epic}" ]; then
    echo ".pm/epics/${epic}/"
    return 0
  fi

  # Neither exists — return new-layout default for creation.
  # Use the first initiative directory found, or fall back to <epic>/<epic>/.
  local first_initiative
  for first_initiative in .pm/initiatives/*/; do
    if [ -d "$first_initiative" ]; then
      local initiative_name
      initiative_name="$(basename "$first_initiative")"
      echo ".pm/initiatives/${initiative_name}/${epic}/"
      return 0
    fi
  done

  # No initiatives exist at all — use epic name as both initiative and epic
  echo ".pm/initiatives/${epic}/${epic}/"
}
