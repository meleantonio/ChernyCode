#!/bin/bash
#
# ChernyCode Installer
# Installs personal skills and subagents for Claude Code and Cursor
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/meleantonio/ChernyCode/main/install.sh | bash
#
# Or clone the repo and run:
#   ./install.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Determine source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)"

# Check if running from repo or via curl
if [[ -n "${BASH_SOURCE[0]:-}" && -d "$SCRIPT_DIR/claude_personal_skills" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
    info "Running from local repository: $SOURCE_DIR"
else
    # Running via curl - clone to temp directory
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    info "Cloning ChernyCode repository..."
    git clone --depth 1 https://github.com/meleantonio/ChernyCode.git "$TEMP_DIR" 2>/dev/null || \
        error "Failed to clone repository. Check your internet connection."
    SOURCE_DIR="$TEMP_DIR"
    success "Repository cloned"
fi

echo ""
echo "============================================"
echo "       ChernyCode Installer"
echo "============================================"
echo ""

# Step 1: Create directories
info "Creating directories..."

mkdir -p ~/.claude/skills
mkdir -p ~/.claude/agents
mkdir -p ~/.cursor/skills-cursor
mkdir -p ~/.cursor/agents

success "Directories created"

# Step 2: Install Claude Code personal skills
info "Installing Claude Code personal skills..."

if [[ -d "$SOURCE_DIR/claude_personal_skills" ]]; then
    for skill_dir in "$SOURCE_DIR"/claude_personal_skills/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            cp -r "${skill_dir%/}" ~/.claude/skills/
            success "  Installed skill: $skill_name"
        fi
    done
else
    warn "  No Claude personal skills found"
fi

# Step 3: Install Claude Code subagents
info "Installing Claude Code subagents..."

if [[ -d "$SOURCE_DIR/claude_subagents" ]]; then
    for agent_file in "$SOURCE_DIR"/claude_subagents/*.md; do
        if [[ -f "$agent_file" ]]; then
            agent_name=$(basename "$agent_file")
            cp "$agent_file" ~/.claude/agents/
            success "  Installed agent: $agent_name"
        fi
    done
else
    warn "  No Claude subagents found"
fi

# Step 4: Install Cursor personal skills
info "Installing Cursor personal skills..."

if [[ -d "$SOURCE_DIR/cursor_personal_skills" ]]; then
    for skill_dir in "$SOURCE_DIR"/cursor_personal_skills/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            cp -r "${skill_dir%/}" ~/.cursor/skills-cursor/
            success "  Installed skill: $skill_name"
        fi
    done
else
    warn "  No Cursor personal skills found"
fi

# Step 5: Install Cursor subagents
info "Installing Cursor subagents..."

if [[ -d "$SOURCE_DIR/cursor_subagents" ]]; then
    for agent_file in "$SOURCE_DIR"/cursor_subagents/*.md; do
        if [[ -f "$agent_file" ]]; then
            agent_name=$(basename "$agent_file")
            cp "$agent_file" ~/.cursor/agents/
            success "  Installed agent: $agent_name"
        fi
    done
else
    warn "  No Cursor subagents found"
fi

# Step 6: Install personal CLAUDE.md
info "Installing personal CLAUDE.md..."

if [[ ! -f ~/.claude/CLAUDE.md ]]; then
    cp "$SOURCE_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
    success "Personal CLAUDE.md installed"
    info "Edit ~/.claude/CLAUDE.md to customize your preferences"
else
    # File exists - ask user what to do
    if [[ -t 0 ]]; then
        # Interactive mode - prompt user
        warn "~/.claude/CLAUDE.md already exists"
        read -p "Overwrite with new version? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$SOURCE_DIR/CLAUDE.md" ~/.claude/CLAUDE.md
            success "Personal CLAUDE.md updated"
        else
            info "Kept existing CLAUDE.md"
        fi
    else
        # Non-interactive - don't overwrite existing file
        warn "~/.claude/CLAUDE.md already exists, skipping (run interactively to overwrite)"
    fi
fi

echo ""
echo "============================================"
echo -e "${GREEN}Installation complete!${NC}"
echo "============================================"
echo ""
echo "Installed to:"
echo "  ~/.claude/skills/      - Claude Code personal skills"
echo "  ~/.claude/agents/      - Claude Code subagents"
echo "  ~/.cursor/skills-cursor/ - Cursor personal skills"
echo "  ~/.cursor/agents/      - Cursor subagents"
echo ""
echo "Next steps:"
echo "  1. Copy CLAUDE.md and AGENTS.md to your project root"
echo "  2. Copy .cursor/skills/ to your project's .cursor/ directory"
echo "  3. Customize the files for your project"
echo ""
echo "For more info, visit: https://github.com/meleantonio/ChernyCode"
echo ""
