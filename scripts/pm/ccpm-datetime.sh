#!/bin/bash
# ccpm-datetime.sh — Outputs the current UTC timestamp in ISO 8601 format.
#
# Usage: bash scripts/pm/ccpm-datetime.sh
# Output: 2026-03-06T17:42:48Z (example)

date -u +"%Y-%m-%dT%H:%M:%SZ"
exit 0
