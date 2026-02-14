# Quick Install

## Unix/Linux/macOS

```bash
# Install latest release
curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash

# Install a specific version
curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash -s -- --version v1.0.0

# Install into a third-party project (uses .git/info/exclude instead of .gitignore)
curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash -s -- --third-party
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash
```

### Options

| Flag | Description |
|------|-------------|
| `--version <tag>` | Install a specific GitHub Release (e.g. `v1.0.0`). Without this, the latest release is used. |
| `--third-party` | Use `.git/info/exclude` instead of `.gitignore`. Use when installing into a project you do not own. |
| `--help` | Show usage information. |

## Windows (cmd)

```cmd
curl -o ccpm.bat https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.bat && ccpm.bat
```

With options:

```cmd
ccpm.bat --version v1.0.0
ccpm.bat --third-party
```

> Note: The Windows script requires PowerShell for version resolution and downloads.
> `tar` is required for release extraction (available on Windows 10+).

## Upgrade Detection

If CCPM is already installed, the script detects the current version
(stored in `.claude/ccpm/.version`) and offers to upgrade, skip, or overwrite.
