# ChernyCode

A template repository implementing Boris Cherny's productivity tips for AI-assisted coding with **Claude Code** and **VS Code**.

Boris Cherny is the creator of Claude Code. This repo synthesizes his recommendations from two threads on how he and the Claude Code team use the tool, providing ready-to-use configurations for maximum productivity.

## What's Included

| File/Directory | Purpose |
|----------------|---------|
| `setup.sh` | One-time environment bootstrap (new machine setup) |
| `idea.sh` | Scaffold a new project with Claude Code config |
| `standardize.sh` | Bring an existing project inline with standards |
| `CLAUDE.md` | Template project memory for Claude Code |
| `claude_personal_skills/` | Personal Claude Code skills |
| `claude_subagents/` | Claude Code subagent definitions |

## Quick Start

### New Machine Setup

Clone this repo and run the setup script:

```bash
git clone https://github.com/yourusername/Claude-Code-agent.git
cd Claude-Code-agent
./setup.sh
```

This installs your personal skills, subagents, and global CLAUDE.md to `~/.claude/`, and optionally makes `idea.sh` available globally.

### Start a New Project

```bash
idea.sh -name "my-cool-project"
```

The script interactively prompts you for:
- Project description
- Parent directory (default: `~/Documents/GitHub/`)
- Project type: Cloudflare Worker, Pages, Python, or generic
- Primary language
- GitHub repo creation (public/private)

Then scaffolds the project with CLAUDE.md, .gitignore, README, language-specific starter files, git init, and optionally creates the GitHub repo.

### Standardize an Existing Project

```bash
cd ~/Documents/GitHub/my-old-project
standardize.sh
```

Or pass a path:

```bash
standardize.sh -path ~/Documents/GitHub/my-old-project
```

The script:
- Auto-detects languages (TypeScript, Python) and project type (Cloudflare Worker, etc.)
- Adds CLAUDE.md with appropriate coding standards, or merges missing sections into an existing one
- Updates .gitignore with missing entries (preserves existing)
- Adds .github/CODEOWNERS if missing
- Creates a starter README.md if missing
- Checks that personal skills/agents are installed in `~/.claude/`

## Key Concepts

### Memory Files (CLAUDE.md)

These files provide persistent context that Claude reads at the start of every session:

- **Project-level** (`./CLAUDE.md`): Shared with your team via git
- **Personal** (`~/.claude/CLAUDE.md`): Your preferences across all projects
- **Local** (`./CLAUDE.local.md`): Personal project settings, gitignored

**Best Practice**: After every correction, say:
> "Update CLAUDE.md so you don't make that mistake again"

Claude is excellent at writing rules for itself.

### Skills

Skills are reusable workflows you can invoke with `/skill-name`:

| Skill | Description |
|-------|-------------|
| `/commit-push-pr` | Commit, push, and create a PR |
| `/techdebt` | Find and fix technical debt |
| `/code-simplifier` | Clean up code after changes |

### Subagents

Subagents run specialized tasks in their own context window, enabling parallel execution and context isolation:

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Review code as a senior engineer (readonly) |
| `test-writer` | Write comprehensive tests (proactive) |
| `doc-generator` | Generate documentation |

Use subagents by:
- Slash command: `/code-reviewer review my changes`
- Natural language: "use the code-reviewer agent to review my changes"

## Boris Cherny's Top Tips

### 1. Start in Plan Mode

For complex tasks, start in Plan mode:
- **Claude Code**: Press `Shift+Tab` twice

Pour your energy into the plan. A good plan lets Claude one-shot the implementation.

### 2. Work in Parallel

Run multiple Claude sessions simultaneously:
- Use git worktrees for parallel branches
- Run 3-5 sessions on different tasks
- Hand off sessions between terminal and web

### 3. Create Skills for Repeated Workflows

If you do something more than once a day, make it a skill:

```bash
# Create a new skill
mkdir -p ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

# My Skill

Instructions for Claude...
EOF
```

### 4. Give Claude Verification Methods

The most important tip: **Give Claude a way to verify its work.**

- Run tests after changes
- Use browser testing for UI
- Check linter output
- Verify with `git diff`

### 5. Continuously Update CLAUDE.md

After every mistake or correction:
> "Update CLAUDE.md so you don't make that mistake again"

Over time, Claude's error rate will measurably drop.

### 6. Use Voice Dictation

On macOS, press `fn` twice to dictate. You speak 3x faster than you type, and your prompts become more detailed.

## Repository Structure

```
Claude-Code-agent/
├── setup.sh                       # One-time environment bootstrap
├── idea.sh                        # New project scaffolding script
├── standardize.sh                 # Update existing projects to standards
├── README.md
├── CLAUDE.md                      # Template project memory
├── threads.md                     # Source material from Boris Cherny
│
├── claude_personal_skills/        # Install to ~/.claude/skills/
│   ├── commit-push-pr/SKILL.md
│   ├── techdebt/SKILL.md
│   └── code-simplifier/SKILL.md
│
├── claude_subagents/              # Install to ~/.claude/agents/
│   ├── code-reviewer.md
│   ├── test-writer.md
│   └── doc-generator.md
│
└── .github/
    └── CODEOWNERS
```

## Target Installation Structure

After installation, your home directory will have:

```
~/.claude/
├── CLAUDE.md              # Personal memory (all projects)
├── skills/
│   ├── commit-push-pr/SKILL.md
│   ├── techdebt/SKILL.md
│   └── code-simplifier/SKILL.md
└── agents/
    ├── code-reviewer.md
    ├── test-writer.md
    └── doc-generator.md
```

## Customization

### Edit Project Memory

Update `CLAUDE.md` with:
- Your project's purpose and architecture
- Coding standards specific to your team
- Common commands and workflows
- Known pitfalls (add these as you encounter them)

### Create New Skills

1. Create a directory: `~/.claude/skills/my-skill/`
2. Add `SKILL.md` with frontmatter and instructions
3. Invoke with `/my-skill`

### Create New Subagents

1. Create a file: `~/.claude/agents/my-agent.md`
2. Add frontmatter with `name`, `description`, `allowed-tools`
3. Add the agent's system prompt
4. Use by asking Claude to "use the my-agent agent"

## Sources

Based on Boris Cherny's threads:
- [How I use Claude Code](https://readwise.io/reader/shared/01kgcamtex6zews0fvz94a8qg4)
- [Tips from the Claude Code team](https://readwise.io/reader/shared/01kgb6njjekq2hpxc0ycymbrcg/)

## License

MIT
