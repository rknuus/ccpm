#!/bin/bash

# CCPM Installation Script
# Installs Claude Code Project Manager correctly into .claude directory
# Usage: curl -fsSL https://raw.githubusercontent.com/rknuus/ccpm/main/install/ccpm.sh | bash

set -e  # Exit on error

REPO_URL="https://github.com/rknuus/ccpm.git"
TEMP_DIR=$(mktemp -d)
PROJECT_ROOT=$(pwd)

# Ensure cleanup on exit (success or failure)
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   CCPM Installation Script v1.0        ║"
echo "║   Claude Code Project Manager          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if we're in a project directory
if [ ! -w "$PROJECT_ROOT" ]; then
    echo "❌ Error: No write permission in current directory"
    exit 1
fi

echo "📂 Installation directory: $PROJECT_ROOT"
echo ""

# Step 1: Clone the repository to temp location
echo "📥 Step 1/5: Downloading CCPM..."
if ! git clone --quiet --depth 1 "$REPO_URL" "$TEMP_DIR"; then
    echo "❌ Error: Failed to clone repository from $REPO_URL"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo "   ✅ Download complete"
echo ""

# Step 2: Create .claude directory structure
echo "📁 Step 2/5: Creating directory structure..."
mkdir -p "$PROJECT_ROOT/.claude/ccpm"
mkdir -p "$PROJECT_ROOT/.claude/commands"
echo "   ✅ Directory structure created"
echo ""

# Step 3: Copy CCPM files to .claude/ccpm/
echo "📋 Step 3/5: Installing CCPM files..."
cp -r "$TEMP_DIR/ccpm"/* "$PROJECT_ROOT/.claude/ccpm/"
echo "   ✅ CCPM files installed to .claude/ccpm/"
echo ""

# Step 4: Copy commands to .claude/commands/ for Claude Code discovery
echo "🔗 Step 4/5: Setting up slash commands..."
if [ -d "$PROJECT_ROOT/.claude/ccpm/commands" ]; then
    cp -r "$PROJECT_ROOT/.claude/ccpm/commands"/* "$PROJECT_ROOT/.claude/commands/"
    echo "   ✅ Slash commands installed to .claude/commands/"
else
    echo "   ⚠️  No commands directory found in CCPM"
fi
echo ""

# Step 5: Update settings if needed
echo "⚙️  Step 5/5: Configuring permissions..."
if [ -f "$PROJECT_ROOT/.claude/ccpm/settings.local.json" ]; then
    cp "$PROJECT_ROOT/.claude/ccpm/settings.local.json" "$PROJECT_ROOT/.claude/settings.local.json"
    echo "   ✅ Settings configured"
else
    echo "   ⚠️  No default settings found, skipping"
fi
echo ""

# Note: Cleanup of temp directory handled automatically by trap on exit

# Update .gitignore
echo "📝 Updating .gitignore..."
if [ ! -f "$PROJECT_ROOT/.gitignore" ]; then
    # Create new .gitignore
    cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# CCPM - Local workspace files
.claude/epics/

# Local settings
.claude/settings.local.json
EOF
    echo "   ✅ .gitignore created"
else
    # Append CCPM entries if they don't exist
    if ! grep -q ".claude/epics/" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo "" >> "$PROJECT_ROOT/.gitignore"
        echo "# CCPM - Local workspace files" >> "$PROJECT_ROOT/.gitignore"
        echo ".claude/epics/" >> "$PROJECT_ROOT/.gitignore"
        echo ".claude/settings.local.json" >> "$PROJECT_ROOT/.gitignore"
        echo "   ✅ .gitignore updated with CCPM exclusions"
    else
        echo "   ✅ .gitignore already contains CCPM exclusions"
    fi
fi
echo ""

# Success message
echo "╔════════════════════════════════════════╗"
echo "║  ✅ CCPM Installation Complete!        ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "📊 Installation Summary:"
echo "   • CCPM files: .claude/ccpm/"
echo "   • Commands:   .claude/commands/"
echo "   • Settings:   .claude/settings.local.json"
echo ""
echo "🎯 Next Steps:"
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
echo "⚠️  IMPORTANT: You must restart Claude Code for slash"
echo "   commands to be recognized!"
echo ""
echo "📚 Documentation: https://github.com/rknuus/ccpm"
echo ""

exit 0
