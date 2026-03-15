#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "╚██████╗╚██████╗██║     ██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"

echo "┌─────────────────────────────────┐"
echo "│ Claude Code Project Management  │"
echo "│ by https://x.com/aroussi        │"
echo "└─────────────────────────────────┘"
echo "https://github.com/automazeio/ccpm"
echo ""
echo ""

echo "🚀 Initializing Claude Code PM System"
echo "======================================"
echo ""

# Check for required tools
echo "🔍 Checking dependencies..."

# Check jq
if command -v jq &> /dev/null; then
  echo "  ✅ jq installed"
else
  echo "  ❌ jq not found (required for stats collection)"
  echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
fi

# Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p .pm/initiatives
mkdir -p .pm/epics
mkdir -p .pm/stats/initiatives
mkdir -p .pm/stats/epics
mkdir -p .pm/stats/tasks
mkdir -p .claude/rules
echo "  ✅ Directories created"

# Copy rules from plugin
echo ""
echo "📋 Installing rules..."
PLUGIN_RULES="${CLAUDE_PLUGIN_ROOT}/rules"
if [ -d "$PLUGIN_RULES" ]; then
  cp -n "$PLUGIN_RULES"/*.md .claude/rules/ 2>/dev/null
  echo "  ✅ Rules installed to .claude/rules/"
else
  echo "  ⚠️ Plugin rules directory not found — skipping"
fi

# Initialize global task ID counter
if [ ! -f .pm/next-id ]; then
  echo "1" > .pm/next-id
  echo "  ✅ Task ID counter initialized"
else
  echo "  ✅ Task ID counter already exists"
fi

# Check for git
echo ""
echo "🔗 Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ✅ Git repository detected"

  # Check remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  ✅ Remote configured: $remote_url"
  else
    echo "  ⚠️ No remote configured"
    echo "  Add with: git remote add origin <url>"
  fi
else
  echo "  ⚠️ Not a git repository"
  echo "  Initialize with: git init"
fi

# Summary
echo ""
echo "✅ Initialization Complete!"
echo "=========================="
echo ""
echo "🎯 Next Steps:"
echo "  1. Create your first Initiative: /ccpm:initiative-new <feature-name>"
echo "  2. View help: /ccpm:help"
echo "  3. Check status: /ccpm:status"
echo ""
echo "📚 Documentation: README.md"

exit 0
