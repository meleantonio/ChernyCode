#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# setup.sh — Bootstrap Claude Code environment on a new machine
# Clone this repo, run ./setup.sh, and you're ready to go.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()    { echo -e "${YELLOW}>>>${NC} $1"; }
error()   { echo -e "${RED}>>>${NC} $1" >&2; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- Check prerequisites ---
info "Checking prerequisites..."

MISSING=()
command -v git &>/dev/null  || MISSING+=("git")
command -v gh &>/dev/null   || MISSING+=("gh (GitHub CLI)")
command -v code &>/dev/null || MISSING+=("code (VS Code CLI)")

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing tools (optional but recommended):"
    for tool in "${MISSING[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo -n "Continue anyway? (Y/n) "
    read -r CONT
    if [[ "$CONT" =~ ^[Nn] ]]; then
        exit 0
    fi
else
    success "All prerequisites found."
fi

# --- Create directory structure ---
info "Setting up ~/.claude/ directory..."
mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/agents"

# --- Install personal CLAUDE.md ---
if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
    warn "~/.claude/CLAUDE.md already exists."
    echo -e "${BLUE}>>>${NC} Overwrite with template? (y/N)"
    read -r OVERWRITE_CLAUDE
    if [[ "$OVERWRITE_CLAUDE" =~ ^[Yy] ]]; then
        cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
        success "Updated ~/.claude/CLAUDE.md"
    else
        info "Skipped — keeping existing CLAUDE.md"
    fi
else
    cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    success "Installed ~/.claude/CLAUDE.md"
fi

# --- Install personal skills ---
info "Installing personal skills..."
if [[ -d "$SCRIPT_DIR/claude_personal_skills" ]]; then
    for skill_dir in "$SCRIPT_DIR/claude_personal_skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        target="$HOME/.claude/skills/$skill_name"
        if [[ -d "$target" ]]; then
            warn "Skill '$skill_name' exists — updating..."
            rm -rf "$target"
        fi
        cp -r "$skill_dir" "$target"
        success "Installed skill: $skill_name"
    done
else
    warn "No skills found in repo — skipping."
fi

# --- Install subagents ---
info "Installing subagents..."
if [[ -d "$SCRIPT_DIR/claude_subagents" ]]; then
    for agent_file in "$SCRIPT_DIR/claude_subagents"/*.md; do
        agent_name="$(basename "$agent_file")"
        target="$HOME/.claude/agents/$agent_name"
        if [[ -f "$target" ]]; then
            warn "Agent '$agent_name' exists — updating..."
        fi
        cp "$agent_file" "$target"
        success "Installed agent: $agent_name"
    done
else
    warn "No subagents found in repo — skipping."
fi

# --- Create default projects directory ---
DEFAULT_PROJECTS="$HOME/Documents/GitHub"
if [[ ! -d "$DEFAULT_PROJECTS" ]]; then
    info "Creating projects directory: $DEFAULT_PROJECTS"
    mkdir -p "$DEFAULT_PROJECTS"
    success "Created $DEFAULT_PROJECTS"
else
    success "Projects directory exists: $DEFAULT_PROJECTS"
fi

# --- Make idea.sh accessible ---
echo ""
info "Make idea.sh available globally?"
echo "  This adds a symlink so you can run 'idea.sh' from anywhere."
echo -e "${BLUE}>>>${NC} Add to /usr/local/bin? (Y/n)"
read -r LINK_IDEA
LINK_IDEA="${LINK_IDEA:-y}"
if [[ "$LINK_IDEA" =~ ^[Yy] ]]; then
    if [[ -L "/usr/local/bin/idea.sh" ]] || [[ -f "/usr/local/bin/idea.sh" ]]; then
        warn "Replacing existing /usr/local/bin/idea.sh"
    fi
    ln -sf "$SCRIPT_DIR/idea.sh" /usr/local/bin/idea.sh 2>/dev/null || {
        warn "Permission denied — trying with sudo..."
        sudo ln -sf "$SCRIPT_DIR/idea.sh" /usr/local/bin/idea.sh
    }
    success "idea.sh linked to /usr/local/bin/idea.sh"
fi

# --- Summary ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Setup complete!"
echo ""
echo "  Installed to ~/.claude/:"
echo "    CLAUDE.md        — global memory"
echo "    skills/          — personal skills"
echo "    agents/          — subagent definitions"
echo ""
echo "  To scaffold a new project:"
echo "    idea.sh -name \"my-project\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
