# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

- See [README](README.md) for background about the project
- Cover new/changed code by tests, unless coverage is not possible: in this case confirm with the user
- Always lint code before committing and only disable rules for genuine false positives, not for non-idiomatic code
- Always run tests before committing
- Avoid code duplication
- Avoid `$()` in common operations like `git commit` (OK for rare, specific exceptions)
- Beware that CCPM (this project) is used when working on this project: do not change files in `.claude/` but rather in the other directories

## Code Style

Follow existing patterns in the codebase