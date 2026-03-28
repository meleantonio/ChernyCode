#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# idea.sh — Scaffold a new project with Claude Code configuration
# Usage: ./idea.sh -name "my-project"
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PARENT="$HOME/Documents/GitHub"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${BLUE}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()  { echo -e "${YELLOW}>>>${NC} $1"; }
error() { echo -e "${RED}>>>${NC} $1" >&2; }

# --- Parse args ---
PROJECT_NAME=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -name|--name) PROJECT_NAME="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: idea.sh -name <project-name>"
            echo ""
            echo "Scaffold a new project with Claude Code configuration."
            echo "Interactively prompts for project details."
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${BLUE}>>>${NC} What's the project name?"
    read -r PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
        error "Project name is required."
        exit 1
    fi
fi

# --- Interactive prompts ---
echo ""
info "Setting up project: $PROJECT_NAME"
echo ""

# Description
echo -e "${BLUE}>>>${NC} One-line project description:"
read -r PROJECT_DESC

# Parent directory
echo ""
echo -e "${BLUE}>>>${NC} Parent directory? (default: $DEFAULT_PARENT)"
read -r PARENT_DIR
PARENT_DIR="${PARENT_DIR:-$DEFAULT_PARENT}"

# Check if directory already exists
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"
if [[ -d "$PROJECT_DIR" ]]; then
    error "Directory already exists: $PROJECT_DIR"
    exit 1
fi

# Project type
echo ""
echo -e "${BLUE}>>>${NC} Project type:"
echo "  1) worker     — Cloudflare Worker (API/serverless)"
echo "  2) pages      — Cloudflare Pages (static site/frontend)"
echo "  3) python     — Python project"
echo "  4) generic    — Language-agnostic / other"
echo ""
echo -n "Choose [1-4]: "
read -r TYPE_CHOICE
case "$TYPE_CHOICE" in
    1) PROJECT_TYPE="worker" ;;
    2) PROJECT_TYPE="pages" ;;
    3) PROJECT_TYPE="python" ;;
    4) PROJECT_TYPE="generic" ;;
    *) PROJECT_TYPE="generic" ;;
esac

# Primary language (skip if already implied)
if [[ "$PROJECT_TYPE" == "worker" || "$PROJECT_TYPE" == "pages" ]]; then
    PRIMARY_LANG="typescript"
elif [[ "$PROJECT_TYPE" == "python" ]]; then
    PRIMARY_LANG="python"
else
    echo ""
    echo -e "${BLUE}>>>${NC} Primary language:"
    echo "  1) typescript"
    echo "  2) python"
    echo "  3) both"
    echo "  4) other"
    echo ""
    echo -n "Choose [1-4]: "
    read -r LANG_CHOICE
    case "$LANG_CHOICE" in
        1) PRIMARY_LANG="typescript" ;;
        2) PRIMARY_LANG="python" ;;
        3) PRIMARY_LANG="both" ;;
        *) PRIMARY_LANG="other" ;;
    esac
fi

# GitHub repo
echo ""
echo -e "${BLUE}>>>${NC} Create GitHub repo? (Y/n)"
read -r CREATE_REPO
CREATE_REPO="${CREATE_REPO:-y}"

if [[ "$CREATE_REPO" =~ ^[Yy] ]]; then
    echo -e "${BLUE}>>>${NC} Visibility: (1) private  (2) public  (default: private)"
    read -r VISIBILITY_CHOICE
    case "$VISIBILITY_CHOICE" in
        2) REPO_VISIBILITY="public" ;;
        *) REPO_VISIBILITY="private" ;;
    esac
fi

# --- Confirm ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Project:     ${GREEN}$PROJECT_NAME${NC}"
echo -e "  Description: $PROJECT_DESC"
echo -e "  Location:    $PROJECT_DIR"
echo -e "  Type:        $PROJECT_TYPE"
echo -e "  Language:    $PRIMARY_LANG"
if [[ "$CREATE_REPO" =~ ^[Yy] ]]; then
echo -e "  GitHub:      $REPO_VISIBILITY repo"
else
echo -e "  GitHub:      skip"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -n "Proceed? (Y/n) "
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Nn] ]]; then
    info "Cancelled."
    exit 0
fi

# ============================================================================
# SCAFFOLDING
# ============================================================================

info "Creating project directory..."
mkdir -p "$PROJECT_DIR"

# --- .gitignore ---
info "Creating .gitignore..."
cat > "$PROJECT_DIR/.gitignore" << 'GITIGNORE'
# macOS
.DS_Store
._*

# Environment & secrets
.env
.env.local
.env.*.local

# Claude Code local config
*.local.md
CLAUDE.local.md

# Logs
*.log
logs/
GITIGNORE

if [[ "$PRIMARY_LANG" == "typescript" || "$PRIMARY_LANG" == "both" ]]; then
cat >> "$PROJECT_DIR/.gitignore" << 'GITIGNORE'

# Node
node_modules/
dist/
.wrangler/
*.tsbuildinfo
GITIGNORE
fi

if [[ "$PRIMARY_LANG" == "python" || "$PRIMARY_LANG" == "both" ]]; then
cat >> "$PROJECT_DIR/.gitignore" << 'GITIGNORE'

# Python
__pycache__/
*.py[cod]
*.so
.Python
build/
dist/
*.egg-info/
.pytest_cache/
.coverage
htmlcov/
.ruff_cache/
venv/
.venv/
GITIGNORE
fi

# --- .github/CODEOWNERS ---
info "Creating .github/CODEOWNERS..."
mkdir -p "$PROJECT_DIR/.github"
echo "* @$(git config user.name 2>/dev/null || echo 'your-username')" > "$PROJECT_DIR/.github/CODEOWNERS"

# --- README.md ---
info "Creating README.md..."
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

$PROJECT_DESC

## Getting Started

TODO: Add setup instructions.

## Development

TODO: Add development workflow.

## License

MIT
EOF

# --- Project-type-specific files ---
case "$PROJECT_TYPE" in
    worker)
        info "Scaffolding Cloudflare Worker..."
        mkdir -p "$PROJECT_DIR/src"

        cat > "$PROJECT_DIR/wrangler.toml" << EOF
name = "$PROJECT_NAME"
main = "src/index.ts"
compatibility_date = "$(date +%Y-%m-%d)"

# [vars]
# MY_VAR = "value"

# [[kv_namespaces]]
# binding = "MY_KV"
# id = ""

# [[d1_databases]]
# binding = "DB"
# database_name = ""
# database_id = ""

# [[r2_buckets]]
# binding = "MY_BUCKET"
# bucket_name = ""
EOF

        cat > "$PROJECT_DIR/src/index.ts" << 'EOF'
export interface Env {
    // Example bindings:
    // MY_KV: KVNamespace;
    // DB: D1Database;
    // MY_BUCKET: R2Bucket;
}

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        return new Response("Hello World");
    },
} satisfies ExportedHandler<Env>;
EOF

        cat > "$PROJECT_DIR/tsconfig.json" << 'EOF'
{
    "compilerOptions": {
        "target": "ESNext",
        "module": "ESNext",
        "moduleResolution": "Bundler",
        "strict": true,
        "noUncheckedIndexedAccess": true,
        "lib": ["ESNext"],
        "types": ["@cloudflare/workers-types"]
    },
    "include": ["src"]
}
EOF

        cat > "$PROJECT_DIR/package.json" << EOF
{
    "name": "$PROJECT_NAME",
    "private": true,
    "scripts": {
        "dev": "wrangler dev",
        "deploy": "wrangler deploy",
        "test": "vitest"
    },
    "devDependencies": {
        "@cloudflare/workers-types": "^4",
        "wrangler": "^4",
        "typescript": "^5",
        "vitest": "^3"
    }
}
EOF
        ;;

    pages)
        info "Scaffolding Cloudflare Pages..."
        mkdir -p "$PROJECT_DIR/src"

        cat > "$PROJECT_DIR/src/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME</title>
</head>
<body>
    <h1>$PROJECT_NAME</h1>
    <p>$PROJECT_DESC</p>
</body>
</html>
EOF

        cat > "$PROJECT_DIR/tsconfig.json" << 'EOF'
{
    "compilerOptions": {
        "target": "ESNext",
        "module": "ESNext",
        "moduleResolution": "Bundler",
        "strict": true,
        "lib": ["ESNext", "DOM"]
    },
    "include": ["src"]
}
EOF

        cat > "$PROJECT_DIR/package.json" << EOF
{
    "name": "$PROJECT_NAME",
    "private": true,
    "scripts": {
        "dev": "wrangler pages dev src",
        "deploy": "wrangler pages deploy src"
    },
    "devDependencies": {
        "wrangler": "^4",
        "typescript": "^5"
    }
}
EOF
        ;;

    python)
        info "Scaffolding Python project..."
        mkdir -p "$PROJECT_DIR/src/$PROJECT_NAME" "$PROJECT_DIR/tests"

        cat > "$PROJECT_DIR/pyproject.toml" << EOF
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$PROJECT_DESC"
requires-python = ">=3.10"

[tool.ruff]
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF

        cat > "$PROJECT_DIR/src/$PROJECT_NAME/__init__.py" << 'EOF'
"""Package init."""
EOF

        cat > "$PROJECT_DIR/tests/__init__.py" << 'EOF'
EOF
        ;;

    generic)
        info "Scaffolding generic project..."
        mkdir -p "$PROJECT_DIR/src"
        ;;
esac

# --- CLAUDE.md ---
info "Generating CLAUDE.md..."

# Build language-specific coding standards
CODING_STANDARDS=""

if [[ "$PRIMARY_LANG" == "python" || "$PRIMARY_LANG" == "both" ]]; then
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

if [[ "$PRIMARY_LANG" == "typescript" || "$PRIMARY_LANG" == "both" ]]; then
CODING_STANDARDS+="
### TypeScript
- **Strict mode** enabled — no implicit \`any\`
- Prefer \`const\` over \`let\`; avoid \`var\`
- Naming: camelCase for functions/variables, PascalCase for types/interfaces
"
fi

if [[ "$PROJECT_TYPE" == "worker" || "$PROJECT_TYPE" == "pages" ]]; then
CODING_STANDARDS+="
### Cloudflare
- Use \`wrangler dev\` for local development
- Use \`wrangler deploy\` for deployment
- Use Cloudflare Workers Secrets (\`wrangler secret put\`) for sensitive config
- Prefer Cloudflare services (D1, KV, R2) over external alternatives where possible
"
fi

cat > "$PROJECT_DIR/CLAUDE.md" << EOF
# Project Memory — $PROJECT_NAME

$PROJECT_DESC

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
$(case "$PROJECT_TYPE" in
    worker) echo "- \`wrangler.toml\` — Cloudflare Worker config
- \`src/index.ts\` — Worker entry point" ;;
    pages) echo "- \`src/index.html\` — Pages entry point" ;;
    python) echo "- \`pyproject.toml\` — Python project config
- \`src/$PROJECT_NAME/\` — Source code
- \`tests/\` — Test suite" ;;
esac)

## Known Pitfalls

<!-- Add pitfalls as they are discovered -->

---
*Update this file whenever Claude makes a mistake: "Update CLAUDE.md so you don't make that mistake again"*
EOF

# --- Install personal skills/agents if missing ---
echo ""
if [[ ! -d "$HOME/.claude/skills" ]] || [[ ! -d "$HOME/.claude/agents" ]]; then
    warn "Personal Claude Code skills/agents not found in ~/.claude/"
    if [[ -d "$SCRIPT_DIR/claude_personal_skills" ]] && [[ -d "$SCRIPT_DIR/claude_subagents" ]]; then
        echo -e "${BLUE}>>>${NC} Install them now? (Y/n)"
        read -r INSTALL_PERSONAL
        INSTALL_PERSONAL="${INSTALL_PERSONAL:-y}"
        if [[ "$INSTALL_PERSONAL" =~ ^[Yy] ]]; then
            mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"
            cp -r "$SCRIPT_DIR/claude_personal_skills/"* "$HOME/.claude/skills/"
            cp -r "$SCRIPT_DIR/claude_subagents/"* "$HOME/.claude/agents/"
            success "Installed personal skills and agents to ~/.claude/"
        fi
    fi
else
    success "Personal skills/agents already installed in ~/.claude/"
fi

# --- Git init ---
info "Initializing git..."
cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "chore: scaffold $PROJECT_NAME project

Generated by idea.sh from Claude-Code-agent template."

# --- GitHub repo ---
if [[ "$CREATE_REPO" =~ ^[Yy] ]]; then
    if command -v gh &> /dev/null; then
        info "Creating GitHub repo ($REPO_VISIBILITY)..."
        gh repo create "$PROJECT_NAME" --"$REPO_VISIBILITY" --source=. --push
        success "GitHub repo created and pushed."
    else
        warn "gh CLI not found — skipping GitHub repo creation."
        warn "Install it: https://cli.github.com"
    fi
fi

# --- Open in VS Code ---
echo ""
echo -e "${BLUE}>>>${NC} Open in VS Code? (Y/n)"
read -r OPEN_VSCODE
OPEN_VSCODE="${OPEN_VSCODE:-y}"
if [[ "$OPEN_VSCODE" =~ ^[Yy] ]]; then
    code "$PROJECT_DIR"
fi

# --- Done ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Project ready: $PROJECT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
