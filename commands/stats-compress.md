# Stats Compress

Compress old JSONL session log files to save disk space.

## Usage
```
/ccpm:stats-compress
```

## Instructions

Run the compression script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pm/stats.sh compress
```

Report the output to the user. If no files were compressed, let the user know all files are either recent or already compressed.
