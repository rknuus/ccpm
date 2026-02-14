#!/bin/bash

# CCPM Installation Script
# Installs Claude Code Project Manager correctly into .claude directory
# Usage: curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash
# Usage: bash install/ccpm.sh [--version <tag>] [--third-party] [--help]

set -e  # Exit on error

REPO_URL="https://github.com/rknuus/ccpm"
REPO_API="https://api.github.com/repos/rknuus/ccpm"
TEMP_DIR=$(mktemp -d)
PROJECT_ROOT=$(pwd)
VERSION=""
THIRD_PARTY=false
VERSION_FILE=".claude/ccpm/.version"

# Ensure cleanup on exit (success or failure)
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

usage() {
    cat <<'USAGE'
CCPM Installation Script - Claude Code Project Manager

USAGE:
  curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash
  bash install/ccpm.sh [OPTIONS]

OPTIONS:
  --version <tag>   Install a specific release version (e.g. v1.0.0).
                    Without this flag, the latest release is installed.
  --third-party     Use .git/info/exclude instead of .gitignore for
                    exclusions. Use this when installing CCPM into a
                    project you do not own.
  --help            Show this help message and exit.

EXAMPLES:
  # Install latest release
  bash install/ccpm.sh

  # Install a specific version
  bash install/ccpm.sh --version v1.2.0

  # Install into a third-party project (no .gitignore changes)
  bash install/ccpm.sh --third-party

  # Combine flags
  bash install/ccpm.sh --version v1.2.0 --third-party
USAGE
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            if [ -z "${2:-}" ]; then
                echo "Error: --version requires a tag argument"
                exit 1
            fi
            VERSION="$2"
            shift 2
            ;;
        --third-party)
            THIRD_PARTY=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Resolve version: use latest release if not specified
resolve_version() {
    if [ -n "$VERSION" ]; then
        return
    fi
    echo "   Resolving latest release..."
    if command -v curl >/dev/null 2>&1; then
        VERSION=$(curl -fsSL "$REPO_API/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        VERSION=$(wget -qO- "$REPO_API/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    fi
    if [ -z "$VERSION" ]; then
        echo "   No releases found; falling back to main branch"
        VERSION="main"
    fi
}

# Download from release tarball or fall back to git clone
download_source() {
    if [ "$VERSION" = "main" ]; then
        echo "   Cloning main branch..."
        if ! git clone --quiet --depth 1 "$REPO_URL.git" "$TEMP_DIR"; then
            echo "Error: Failed to clone repository from $REPO_URL"
            exit 1
        fi
    else
        local tarball_url="$REPO_URL/archive/refs/tags/$VERSION.tar.gz"
        echo "   Downloading release $VERSION..."
        local archive="$TEMP_DIR/ccpm.tar.gz"
        if command -v curl >/dev/null 2>&1; then
            if ! curl -fsSL -o "$archive" "$tarball_url"; then
                echo "Error: Failed to download release $VERSION"
                exit 1
            fi
        elif command -v wget >/dev/null 2>&1; then
            if ! wget -qO "$archive" "$tarball_url"; then
                echo "Error: Failed to download release $VERSION"
                exit 1
            fi
        else
            echo "Error: Neither curl nor wget available"
            exit 1
        fi
        # Extract: tarball contains a top-level directory like ccpm-v1.0.0/
        tar -xzf "$archive" -C "$TEMP_DIR"
        rm -f "$archive"
        # Move contents of the extracted directory to TEMP_DIR root
        local extracted
        extracted=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
        if [ -n "$extracted" ] && [ "$extracted" != "$TEMP_DIR" ]; then
            # Move all contents up, then remove the now-empty directory
            mv "$extracted"/* "$extracted"/.[!.]* "$TEMP_DIR/" 2>/dev/null || true
            rmdir "$extracted" 2>/dev/null || true
        fi
    fi
}

# Check for existing installation and handle upgrade
check_existing_install() {
    if [ ! -f "$PROJECT_ROOT/$VERSION_FILE" ]; then
        return 0
    fi
    local installed choice
    installed=$(<"$PROJECT_ROOT/$VERSION_FILE")
    if [ "$installed" = "$VERSION" ]; then
        echo ""
        echo "CCPM $installed is already installed."
        printf "   [S]kip / [O]verwrite? (s/o): "
        read -r choice
        case "$choice" in
            [oO])
                echo "   Overwriting..."
                return 0
                ;;
            *)
                echo "   Skipping installation."
                exit 0
                ;;
        esac
    else
        echo ""
        echo "CCPM $installed is currently installed."
        echo "   Available version: $VERSION"
        printf "   [U]pgrade / [S]kip / [O]verwrite? (u/s/o): "
        read -r choice
        case "$choice" in
            [uU]|[oO])
                echo "   Proceeding with installation..."
                return 0
                ;;
            *)
                echo "   Skipping installation."
                exit 0
                ;;
        esac
    fi
}

# Update exclusions: .gitignore or .git/info/exclude
update_exclusions() {
    local entries
    entries="# CCPM - Local workspace files
.claude/epics/

# Local settings
.claude/settings.local.json"

    if [ "$THIRD_PARTY" = true ]; then
        echo "Updating .git/info/exclude (third-party mode)..."
        local exclude_file="$PROJECT_ROOT/.git/info/exclude"
        if [ ! -d "$PROJECT_ROOT/.git/info" ]; then
            echo "   Warning: .git/info directory not found; is this a git repo?"
            return
        fi
        # Add .claude/ and .pm/ exclusions
        if ! grep -q "# CCPM" "$exclude_file" 2>/dev/null; then
            printf '\n# CCPM - Third-party installation\n.claude/\n.pm/\n' >> "$exclude_file"
            echo "   .git/info/exclude updated with CCPM exclusions"
        else
            echo "   .git/info/exclude already contains CCPM exclusions"
        fi
    else
        echo "Updating .gitignore..."
        if [ ! -f "$PROJECT_ROOT/.gitignore" ]; then
            printf '%s\n' "$entries" > "$PROJECT_ROOT/.gitignore"
            echo "   .gitignore created"
        else
            if ! grep -q ".claude/epics/" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
                echo "" >> "$PROJECT_ROOT/.gitignore"
                printf '%s\n' "$entries" >> "$PROJECT_ROOT/.gitignore"
                echo "   .gitignore updated with CCPM exclusions"
            else
                echo "   .gitignore already contains CCPM exclusions"
            fi
        fi
    fi
}

echo ""
echo "========================================"
echo "  CCPM Installation Script"
echo "  Claude Code Project Manager"
echo "========================================"
echo ""

# Check if we're in a project directory
if [ ! -w "$PROJECT_ROOT" ]; then
    echo "Error: No write permission in current directory"
    exit 1
fi

echo "Installation directory: $PROJECT_ROOT"
echo ""

# Step 1: Resolve and download
echo "Step 1/5: Downloading CCPM..."
resolve_version
echo "   Target version: $VERSION"
check_existing_install
download_source
echo "   Download complete"
echo ""

# Step 2: Create .claude directory structure
echo "Step 2/5: Creating directory structure..."
mkdir -p "$PROJECT_ROOT/.claude/ccpm"
mkdir -p "$PROJECT_ROOT/.claude/commands"
echo "   Directory structure created"
echo ""

# Step 3: Copy CCPM files to .claude/ccpm/
echo "Step 3/5: Installing CCPM files..."
cp -r "$TEMP_DIR/ccpm"/* "$PROJECT_ROOT/.claude/ccpm/"
echo "   CCPM files installed to .claude/ccpm/"
echo ""

# Step 4: Copy commands to .claude/commands/ for Claude Code discovery
echo "Step 4/5: Setting up slash commands..."
if [ -d "$PROJECT_ROOT/.claude/ccpm/commands" ]; then
    cp -r "$PROJECT_ROOT/.claude/ccpm/commands"/* "$PROJECT_ROOT/.claude/commands/"
    echo "   Slash commands installed to .claude/commands/"
else
    echo "   Warning: No commands directory found in CCPM"
fi
echo ""

# Step 5: Update settings if needed
echo "Step 5/5: Configuring permissions..."
if [ -f "$PROJECT_ROOT/.claude/ccpm/settings.local.json" ]; then
    cp "$PROJECT_ROOT/.claude/ccpm/settings.local.json" "$PROJECT_ROOT/.claude/settings.local.json"
    echo "   Settings configured"
else
    echo "   No default settings found, skipping"
fi
echo ""

# Note: Cleanup of temp directory handled automatically by trap on exit

# Update exclusions (.gitignore or .git/info/exclude)
update_exclusions
echo ""

# Write version file
echo "$VERSION" > "$PROJECT_ROOT/$VERSION_FILE"
echo "Version $VERSION recorded in $VERSION_FILE"
echo ""

# Success message
echo "========================================"
echo "  CCPM Installation Complete!"
echo "========================================"
echo ""
echo "Installation Summary:"
echo "   CCPM files: .claude/ccpm/"
echo "   Commands:   .claude/commands/"
echo "   Settings:   .claude/settings.local.json"
echo "   Version:    $VERSION"
echo ""
echo "Next Steps:"
echo ""
echo "   1. Initialize CCPM:"
echo "      bash .claude/ccpm/scripts/pm/init.sh"
echo ""
echo "   2. Restart Claude Code to load slash commands"
echo ""
echo "   3. Verify installation:"
echo "      /pm:help"
echo ""
echo "   4. Create your first PRD:"
echo "      /pm:prd-new <feature-name>"
echo ""
echo "   IMPORTANT: You must restart Claude Code for slash"
echo "   commands to be recognized!"
echo ""
echo "Documentation: https://github.com/rknuus/ccpm"
echo ""

exit 0
