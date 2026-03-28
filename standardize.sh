#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# standardize.sh — Bring an existing project inline with Claude Code standards
# Usage: standardize.sh [-path /some/project]
#        (defaults to current directory)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"
BATCH_MODE=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()    { echo -e "${YELLOW}>>>${NC} $1"; }
error()   { echo -e "${RED}>>>${NC} $1" >&2; }
header()  { echo -e "\n${BOLD}── $1 ──${NC}"; }

# Helper: prompt user or use default in batch mode
prompt_or_default() {
    local prompt_text="$1"
    local default_value="$2"
    if $BATCH_MODE; then
        echo "$default_value"
    else
        echo -e "${BLUE}>>>${NC} $prompt_text" >&2
        read -r REPLY
        echo "${REPLY:-$default_value}"
    fi
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -path|--path) PROJECT_DIR="$2"; shift 2 ;;
        --batch) BATCH_MODE=true; shift ;;
        -h|--help)
            echo "Usage: standardize.sh [-path /path/to/project] [--batch]"
            echo ""
            echo "Bring an existing project inline with Claude Code standards."
            echo "Defaults to current directory if -path is not specified."
            echo ""
            echo "Options:"
            echo "  -path, --path    Path to project (default: current directory)"
            echo "  --batch          Non-interactive mode — uses detected values and"
            echo "                   sensible defaults. Appends missing sections to"
            echo "                   existing CLAUDE.md instead of replacing."
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
    error "Directory not found: $PROJECT_DIR"
    exit 1
}

PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Standardize: $PROJECT_NAME"
echo "  Path: $PROJECT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# DETECT project characteristics
# ============================================================================
header "Detecting project type"

HAS_GIT=false
HAS_CLAUDE_MD=false
HAS_GITIGNORE=false
HAS_CODEOWNERS=false
HAS_README=false
DETECTED_LANGS=()
DETECTED_TYPE="generic"

# Git
[[ -d "$PROJECT_DIR/.git" ]] && HAS_GIT=true

# Existing files
[[ -f "$PROJECT_DIR/CLAUDE.md" ]] && HAS_CLAUDE_MD=true
[[ -f "$PROJECT_DIR/.gitignore" ]] && HAS_GITIGNORE=true
[[ -f "$PROJECT_DIR/.github/CODEOWNERS" ]] && HAS_CODEOWNERS=true
[[ -f "$PROJECT_DIR/README.md" ]] && HAS_README=true

# Detect languages
if ls "$PROJECT_DIR"/*.ts "$PROJECT_DIR"/src/*.ts "$PROJECT_DIR"/src/**/*.ts 2>/dev/null | head -1 &>/dev/null || \
   [[ -f "$PROJECT_DIR/tsconfig.json" ]] || [[ -f "$PROJECT_DIR/package.json" ]]; then
    DETECTED_LANGS+=("typescript")
fi

if ls "$PROJECT_DIR"/*.py "$PROJECT_DIR"/src/*.py "$PROJECT_DIR"/src/**/*.py 2>/dev/null | head -1 &>/dev/null || \
   [[ -f "$PROJECT_DIR/pyproject.toml" ]] || [[ -f "$PROJECT_DIR/setup.py" ]] || [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
    DETECTED_LANGS+=("python")
fi

# Detect Cloudflare
if [[ -f "$PROJECT_DIR/wrangler.toml" ]] || [[ -f "$PROJECT_DIR/wrangler.jsonc" ]]; then
    DETECTED_TYPE="worker"
elif grep -q "pages" "$PROJECT_DIR/wrangler.toml" 2>/dev/null; then
    DETECTED_TYPE="pages"
elif [[ ${#DETECTED_LANGS[@]} -eq 0 ]]; then
    DETECTED_TYPE="generic"
fi

# Report findings
echo "  Git repo:      $(${HAS_GIT} && echo 'yes' || echo 'no')"
echo "  CLAUDE.md:     $(${HAS_CLAUDE_MD} && echo 'exists' || echo 'missing')"
echo "  .gitignore:    $(${HAS_GITIGNORE} && echo 'exists' || echo 'missing')"
echo "  CODEOWNERS:    $(${HAS_CODEOWNERS} && echo 'exists' || echo 'missing')"
echo "  README.md:     $(${HAS_README} && echo 'exists' || echo 'missing')"
echo "  Languages:     ${DETECTED_LANGS[*]:-none detected}"
echo "  Project type:  $DETECTED_TYPE"

# Let user confirm/override detected language
if ! $BATCH_MODE; then
    echo ""
    echo -e "${BLUE}>>>${NC} Detected languages: ${DETECTED_LANGS[*]:-none}. Override?"
    echo "  1) typescript"
    echo "  2) python"
    echo "  3) both"
    echo "  4) other"
    echo "  Enter) keep detected"
    echo ""
    echo -n "Choose [1-4 or Enter to keep]: "
    read -r LANG_OVERRIDE
    case "$LANG_OVERRIDE" in
        1) DETECTED_LANGS=("typescript") ;;
        2) DETECTED_LANGS=("python") ;;
        3) DETECTED_LANGS=("typescript" "python") ;;
        4) DETECTED_LANGS=() ;;
        *) ;; # keep detected
    esac
else
    info "Batch mode: using detected languages (${DETECTED_LANGS[*]:-none})"
fi

# ============================================================================
# PLAN changes — show what will happen before doing anything
# ============================================================================
header "Planned changes"

CHANGES=()

if ! $HAS_GIT; then
    CHANGES+=("Initialize git repository")
fi

if ! $HAS_CLAUDE_MD; then
    CHANGES+=("Create CLAUDE.md (generated from project details)")
else
    CHANGES+=("Update CLAUDE.md (merge missing sections, preserve existing content)")
fi

if ! $HAS_GITIGNORE; then
    CHANGES+=("Create .gitignore")
else
    CHANGES+=("Update .gitignore (add missing entries, preserve existing)")
fi

if ! $HAS_CODEOWNERS; then
    CHANGES+=("Create .github/CODEOWNERS")
fi

if ! $HAS_README; then
    CHANGES+=("Create starter README.md")
fi

for i in "${!CHANGES[@]}"; do
    echo "  $((i+1)). ${CHANGES[$i]}"
done

if ! $BATCH_MODE; then
    echo ""
    echo -n "Proceed with these changes? (Y/n) "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        info "Cancelled."
        exit 0
    fi
fi

# ============================================================================
# APPLY changes
# ============================================================================

# --- Git init ---
if ! $HAS_GIT; then
    header "Initializing git"
    cd "$PROJECT_DIR" && git init -q
    success "Git initialized"
fi

# --- .gitignore ---
header "Updating .gitignore"

GITIGNORE_ADDITIONS=""

# Core entries every project needs
CORE_IGNORES=(
    ".DS_Store"
    "._*"
    ".env"
    ".env.local"
    ".env.*.local"
    "*.local.md"
    "CLAUDE.local.md"
    "*.log"
    "logs/"
)

# Language-specific entries
TS_IGNORES=(
    "node_modules/"
    "dist/"
    ".wrangler/"
    "*.tsbuildinfo"
)

PY_IGNORES=(
    "__pycache__/"
    "*.py[cod]"
    "*.so"
    ".Python"
    "build/"
    "dist/"
    "*.egg-info/"
    ".pytest_cache/"
    ".coverage"
    "htmlcov/"
    ".ruff_cache/"
    "venv/"
    ".venv/"
)

add_if_missing() {
    local entry="$1"
    local file="$PROJECT_DIR/.gitignore"
    if [[ ! -f "$file" ]] || ! grep -qxF "$entry" "$file" 2>/dev/null; then
        GITIGNORE_ADDITIONS+="$entry"$'\n'
    fi
}

for entry in "${CORE_IGNORES[@]}"; do
    add_if_missing "$entry"
done

if [[ ${#DETECTED_LANGS[@]} -gt 0 ]]; then
    for lang in "${DETECTED_LANGS[@]}"; do
        if [[ "$lang" == "typescript" ]]; then
            for entry in "${TS_IGNORES[@]}"; do
                add_if_missing "$entry"
            done
        fi
        if [[ "$lang" == "python" ]]; then
            for entry in "${PY_IGNORES[@]}"; do
                add_if_missing "$entry"
            done
        fi
    done
fi

if [[ -n "$GITIGNORE_ADDITIONS" ]]; then
    if [[ -f "$PROJECT_DIR/.gitignore" ]]; then
        echo "" >> "$PROJECT_DIR/.gitignore"
        echo "# Added by standardize.sh" >> "$PROJECT_DIR/.gitignore"
    fi
    echo "$GITIGNORE_ADDITIONS" >> "$PROJECT_DIR/.gitignore"
    success ".gitignore updated ($(echo "$GITIGNORE_ADDITIONS" | grep -c '[^ ]') entries added)"
else
    success ".gitignore already up to date"
fi

# --- CODEOWNERS ---
if ! $HAS_CODEOWNERS; then
    header "Creating CODEOWNERS"
    mkdir -p "$PROJECT_DIR/.github"
    GIT_USER="$(git config user.name 2>/dev/null || echo 'your-username')"
    echo "* @$GIT_USER" > "$PROJECT_DIR/.github/CODEOWNERS"
    success "Created .github/CODEOWNERS"
fi

# --- README.md ---
if ! $HAS_README; then
    header "Creating README.md"
    if $BATCH_MODE; then
        PROJECT_DESC=""
    else
        echo -e "${BLUE}>>>${NC} One-line project description:"
        read -r PROJECT_DESC
    fi
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

${PROJECT_DESC:-TODO: Add project description.}

## Getting Started

TODO: Add setup instructions.

## Development

TODO: Add development workflow.

## License

MIT
EOF
    success "Created README.md"
fi

# --- CLAUDE.md ---
header "Setting up CLAUDE.md"

# Build language-specific coding standards
CODING_STANDARDS=""

if [[ ${#DETECTED_LANGS[@]} -gt 0 ]]; then
for lang in "${DETECTED_LANGS[@]}"; do
    if [[ "$lang" == "python" ]]; then
CODING_STANDARDS+="
### Python
- **Version**: Python 3.10+
- **Formatter**: Ruff (\`ruff format .\`, \`ruff check --fix .\`)
- **Testing**: pytest with 80%+ coverage
- **Type hints**: Required for all functions
- **Docstrings**: Google-style
- **Naming**: snake_case for functions/variables, PascalCase for classes
"
    fi
    if [[ "$lang" == "typescript" ]]; then
CODING_STANDARDS+="
### TypeScript
- **Strict mode** enabled — no implicit \`any\`
- Prefer \`const\` over \`let\`; avoid \`var\`
- Naming: camelCase for functions/variables, PascalCase for types/interfaces
"
    fi
done
fi

if [[ "$DETECTED_TYPE" == "worker" || "$DETECTED_TYPE" == "pages" ]]; then
CODING_STANDARDS+="
### Cloudflare
- Use \`wrangler dev\` for local development
- Use \`wrangler deploy\` for deployment
- Use Cloudflare Workers Secrets (\`wrangler secret put\`) for sensitive config
- Prefer Cloudflare services (D1, KV, R2) over external alternatives where possible
"
fi

generate_claude_md() {
    cat << EOF
# Project Memory — $PROJECT_NAME

TODO: Add one-line project description.

## Coding Standards
$CODING_STANDARDS
### General
- Indentation: 4 spaces
- Max line length: 120 characters
- Use structured logging

### Security & Secrets
- **Never commit** \`.env\` files, API keys, tokens, or credentials
- Use platform-native secrets management (Cloudflare Secrets, GitHub Secrets)
- Flag any hardcoded secrets found during code review

### Dependency Management
- Prefer minimal dependencies — vet new packages before adding
- Always use lockfiles and commit them
- Pin major versions to avoid breaking changes

### Scope Discipline
- Don't add features, refactoring, or "improvements" beyond what was asked
- Ask before making large architectural changes
- One PR = one concern

### Context Gathering
- Read relevant code before modifying it
- Check \`git log\` / \`git blame\` for recent changes in the area being modified
- Look for existing patterns in the codebase before inventing new ones

### Documentation
- **Proactively create and maintain documentation as features are built**
- Update README when adding features, changing setup steps, or modifying architecture
- Document API endpoints, configuration options, and environment variables as they are created
- PR descriptions should explain the "why", not just the "what"

## Claude Code Skills & Plugins

- At the start of each session, review available skills and plugins
- **Use skills and plugins as frequently as needed** — they exist to improve quality and efficiency
- Proactively invoke relevant skills for code review, testing, commits, PRs, debugging, and planning

## Maintaining CLAUDE.md

- **Keep this file updated as the project evolves** — treat it as a living document
- When new patterns, conventions, pitfalls, or architecture decisions emerge, add them immediately
- When files/directories are added or renamed, update the Key Files section
- When a mistake is made and corrected, add it to Known Pitfalls so it doesn't recur
- Proactively suggest CLAUDE.md updates at the end of sessions where significant work was done

## Common Workflows

### Git Workflow
- **All changes must be made in feature branches with Pull Requests** — never commit directly to main
- Follow GitHub Flow (feature branches from main)
- Every change goes through: branch -> commit -> push -> PR -> review -> merge
- Use Conventional Commits format: feat:, fix:, docs:, refactor:, test:, chore:

### Testing
- Always run tests before committing
- Aim for 80%+ code coverage

### Code Quality
- Run formatter and linter before committing
- Fix all linting issues before pushing

## Key Files

- \`CLAUDE.md\` — This file
- \`README.md\` — Project documentation

## Known Pitfalls

<!-- Add pitfalls as they are discovered -->

---
*Update this file whenever Claude makes a mistake: "Update CLAUDE.md so you don't make that mistake again"*
EOF
}

if $HAS_CLAUDE_MD; then
    # Check for missing sections and offer to merge
    EXISTING="$(cat "$PROJECT_DIR/CLAUDE.md")"
    MISSING_SECTIONS=()

    check_section() {
        local section="$1"
        if ! echo "$EXISTING" | grep -qF "$section"; then
            MISSING_SECTIONS+=("$section")
        fi
    }

    check_section "## Claude Code Skills & Plugins"
    check_section "## Maintaining CLAUDE.md"
    check_section "### Security & Secrets"
    check_section "### Scope Discipline"
    check_section "### Context Gathering"
    check_section "### Documentation"
    check_section "### Dependency Management"
    check_section "## Known Pitfalls"

    if [[ ${#MISSING_SECTIONS[@]} -gt 0 ]]; then
        warn "CLAUDE.md exists but is missing these standard sections:"
        for section in "${MISSING_SECTIONS[@]}"; do
            echo "    $section"
        done

        if $BATCH_MODE; then
            CLAUDE_CHOICE="2"  # auto-append in batch mode
            info "Batch mode: appending missing sections"
        else
            echo ""
            echo -e "${BLUE}>>>${NC} How would you like to handle this?"
            echo "  1) Backup existing & replace with full template"
            echo "  2) Append missing sections to the end"
            echo "  3) Skip — I'll update it manually"
            echo ""
            echo -n "Choose [1-3]: "
            read -r CLAUDE_CHOICE
        fi
        case "$CLAUDE_CHOICE" in
            1)
                cp "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md.backup"
                generate_claude_md > "$PROJECT_DIR/CLAUDE.md"
                success "CLAUDE.md replaced (backup saved as CLAUDE.md.backup)"
                ;;
            2)
                echo "" >> "$PROJECT_DIR/CLAUDE.md"
                echo "<!-- Sections added by standardize.sh -->" >> "$PROJECT_DIR/CLAUDE.md"

                if [[ " ${MISSING_SECTIONS[*]} " =~ "## Claude Code Skills & Plugins" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

## Claude Code Skills & Plugins

- At the start of each session, review available skills and plugins
- **Use skills and plugins as frequently as needed** — they exist to improve quality and efficiency
- Proactively invoke relevant skills for code review, testing, commits, PRs, debugging, and planning
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "## Maintaining CLAUDE.md" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

## Maintaining CLAUDE.md

- **Keep this file updated as the project evolves** — treat it as a living document
- When new patterns, conventions, pitfalls, or architecture decisions emerge, add them immediately
- When files/directories are added or renamed, update the Key Files section
- When a mistake is made and corrected, add it to Known Pitfalls so it doesn't recur
- Proactively suggest CLAUDE.md updates at the end of sessions where significant work was done
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "### Security & Secrets" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

### Security & Secrets
- **Never commit** `.env` files, API keys, tokens, or credentials
- Use platform-native secrets management (Cloudflare Secrets, GitHub Secrets)
- Flag any hardcoded secrets found during code review
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "### Scope Discipline" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

### Scope Discipline
- Don't add features, refactoring, or "improvements" beyond what was asked
- Ask before making large architectural changes
- One PR = one concern
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "### Context Gathering" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

### Context Gathering
- Read relevant code before modifying it
- Check `git log` / `git blame` for recent changes in the area being modified
- Look for existing patterns in the codebase before inventing new ones
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "### Documentation" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

### Documentation
- **Proactively create and maintain documentation as features are built**
- Update README when adding features, changing setup steps, or modifying architecture
- Document API endpoints, configuration options, and environment variables as they are created
- PR descriptions should explain the "why", not just the "what"
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "### Dependency Management" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

### Dependency Management
- Prefer minimal dependencies — vet new packages before adding
- Always use lockfiles and commit them
- Pin major versions to avoid breaking changes
SECTION
                fi

                if [[ " ${MISSING_SECTIONS[*]} " =~ "## Known Pitfalls" ]]; then
                    cat >> "$PROJECT_DIR/CLAUDE.md" << 'SECTION'

## Known Pitfalls

<!-- Add pitfalls as they are discovered -->
SECTION
                fi

                success "Appended ${#MISSING_SECTIONS[@]} missing sections to CLAUDE.md"
                ;;
            3)
                info "Skipped CLAUDE.md update"
                ;;
        esac
    else
        success "CLAUDE.md already has all standard sections"
    fi
else
    # No CLAUDE.md exists — ask for description and generate
    if $BATCH_MODE; then
        PROJECT_DESC_CLAUDE=""
    else
        echo -e "${BLUE}>>>${NC} One-line project description (for CLAUDE.md):"
        read -r PROJECT_DESC_CLAUDE
    fi
    generate_claude_md > "$PROJECT_DIR/CLAUDE.md"
    if [[ -n "${PROJECT_DESC_CLAUDE:-}" ]]; then
        sed -i '' "s|TODO: Add one-line project description.|$PROJECT_DESC_CLAUDE|" "$PROJECT_DIR/CLAUDE.md"
    fi
    success "Created CLAUDE.md"
fi

# --- Ensure personal skills/agents are installed ---
header "Checking personal Claude Code setup"

if [[ ! -d "$HOME/.claude/skills" ]] || [[ ! -d "$HOME/.claude/agents" ]]; then
    warn "Personal skills/agents not found in ~/.claude/"
    if [[ -d "$SCRIPT_DIR/claude_personal_skills" ]] && [[ -d "$SCRIPT_DIR/claude_subagents" ]]; then
        if $BATCH_MODE; then
            INSTALL_PERSONAL="y"
        else
            echo -e "${BLUE}>>>${NC} Install them now? (Y/n)"
            read -r INSTALL_PERSONAL
            INSTALL_PERSONAL="${INSTALL_PERSONAL:-y}"
        fi
        if [[ "$INSTALL_PERSONAL" =~ ^[Yy] ]]; then
            mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"
            cp -r "$SCRIPT_DIR/claude_personal_skills/"* "$HOME/.claude/skills/"
            cp -r "$SCRIPT_DIR/claude_subagents/"* "$HOME/.claude/agents/"
            success "Installed personal skills and agents to ~/.claude/"
        fi
    fi
else
    success "Personal skills/agents already installed"
fi

# --- Summary ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Standardization complete: $PROJECT_NAME"
echo ""
echo "  Next steps:"
echo "    1. Review the generated/updated CLAUDE.md"
echo "    2. Fill in any TODO sections"
echo "    3. Commit the changes on a feature branch"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
