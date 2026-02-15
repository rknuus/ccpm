---
allowed-tools: Bash, Read, Write
---

**IMPORTANT:** Before proceeding, verify CCPM is initialized by checking if `.claude/rules/path-standards.md` exists. If it does not exist, stop immediately and tell the user: "CCPM not initialized. Run: /ccpm:init"

# Stats Rate

Rate or re-rate satisfaction for a work item (delayed rating).

## Usage
```
/ccpm:stats-rate <type> <name>
```

Where:
- `type` is `prd`, `epic`, or `task`
- `name` is the work item name (for PRDs/epics) or issue number (for tasks)

## Instructions

### 1. Parse Arguments

Extract `type` and `name` from `$ARGUMENTS`.
- If fewer than 2 arguments: "Usage: /ccpm:stats-rate <type> <name>"
- Validate type is one of: `prd`, `epic`, `task`

### 2. Show Existing Ratings

Check if `.pm/stats/{type}s/{name}/stats.json` exists:
- If it exists, read and display any existing satisfaction ratings:
  ```
  Existing ratings for {type} "{name}":
    Immediate: {rating}/5 ({timestamp})
    Delayed: {rating}/5 ({timestamp}) - "{note}"
  ```
- If no file or no satisfaction data: "No existing ratings for {type} '{name}'"

### 3. Collect Rating

Ask the user:
- "Rate your satisfaction with this {type} (1-5, or 'skip'):"
- If user says 'skip', exit with: "Rating skipped."
- If rating is not 1-5, ask again

### 4. Collect Note (Optional)

Ask the user:
- "Add an optional note (or press Enter to skip):"
- Store the note if provided

### 5. Save Rating

```bash
source scripts/pm/stats-satisfaction.sh && stats_save_rating {type} {name} delayed {rating} "{note}"
```

### 6. Confirm

Display confirmation:
```
Saved delayed rating for {type} "{name}": {rating}/5
{If note}: Note: "{note}"
```

If there were existing ratings, show them alongside the new one.
