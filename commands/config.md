---
allowed-tools: Bash, Read, Write
---

# Config

View or update CCPM project settings.

## Usage
```
/ccpm:config                       — display current settings
/ccpm:config set <key> <value>     — update a setting
```

## Valid Settings

| Key | Type | Description |
|-----|------|-------------|
| `collectPrompts` | boolean (`true`/`false`) | Whether to collect user prompts during stats computation |

## Instructions

### 1. Parse Arguments

Extract arguments from `$ARGUMENTS`.
- If no arguments (empty or whitespace): **display mode**
- If starts with `set`: **update mode** — extract `<key>` and `<value>` from the remaining arguments
- Otherwise: show usage message

### 2. Display Mode (no arguments)

Read `.pm/ccpm-settings.json` and display it formatted:

```bash
jq '.' .pm/ccpm-settings.json
```

Show output as:
```
CCPM Settings:
  collectPrompts = {value}
```

If the file does not exist: "No settings file found. Run /ccpm:init to initialize."

### 3. Update Mode (`set <key> <value>`)

1. Validate the key is one of: `collectPrompts`
   - If unknown: "Unknown setting: {key}. Valid settings: collectPrompts"
2. Validate the value:
   - For `collectPrompts`: must be `true` or `false`
   - If invalid: "Invalid value for {key}. Expected: true/false"
3. Update the setting:
   ```bash
   jq --argjson val {value} '.{key} = $val' .pm/ccpm-settings.json > .pm/ccpm-settings.json.tmp && mv .pm/ccpm-settings.json.tmp .pm/ccpm-settings.json
   ```
   Note: `{value}` for booleans should be passed as `--argjson` so `true`/`false` become JSON booleans, not strings.
4. Show confirmation: "Setting updated: {key} = {value}"
