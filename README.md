# ChernyCode

A template repository implementing Boris Cherny's productivity tips for AI-assisted coding with **Claude Code** and **Cursor**.

Boris Cherny is the creator of Claude Code. This repo synthesizes his recommendations from two threads on how he and the Claude Code team use the tool, providing ready-to-use configurations for maximum productivity.

## What's Included

| File/Directory | Purpose | Install To |
|----------------|---------|------------|
| `CLAUDE.md` | Project memory for Claude Code | Project root |
| `AGENTS.md` | Agent instructions for Cursor | Project root |
| `.cursor/skills/` | Project-specific Cursor skills | Project `.cursor/skills/` |
| `claude_personal_skills/` | Personal Claude Code skills | `~/.claude/skills/` |
| `claude_subagents/` | Claude Code subagent definitions | `~/.claude/agents/` |
| `cursor_personal_skills/` | Personal Cursor skills | `~/.cursor/skills-cursor/` |
| `cursor_subagents/` | Cursor subagent definitions | `~/.cursor/agents/` |

## Quick Start

### One-Line Install

Install all personal skills and subagents with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/meleantonio/ChernyCode/main/install.sh | bash
```

This installs:
- Claude Code personal skills to `~/.claude/skills/`
- Claude Code subagents to `~/.claude/agents/`
- Cursor personal skills to `~/.cursor/skills-cursor/`
- Cursor subagents to `~/.cursor/agents/`
- Personal CLAUDE.md to `~/.claude/CLAUDE.md`

### Manual Installation

If you prefer to install manually, follow the steps below.

#### 1. Copy Project Files

Copy these files to your project root:
- `CLAUDE.md` - Edit for your project's context
- `AGENTS.md` - Edit for your project's context
- `.cursor/skills/` - Copy the skills directory

#### 2. Install Personal Files

Copy these from this repo to your home directory for use across all projects:

```bash
# Create directories if they don't exist
mkdir -p ~/.claude/skills ~/.claude/agents ~/.cursor/skills-cursor ~/.cursor/agents

# Claude Code personal skills
cp -r claude_personal_skills/* ~/.claude/skills/

# Claude Code subagents
cp -r claude_subagents/* ~/.claude/agents/

# Cursor personal skills
cp -r cursor_personal_skills/* ~/.cursor/skills/

# Cursor subagents
cp -r cursor_subagents/* ~/.cursor/agents/
```

#### 3. (Optional) Install Personal CLAUDE.md

Create a personal memory file for all projects:

```bash
# Copy the template (edit with your preferences)
cp CLAUDE.md ~/.claude/CLAUDE.md
```

## Key Concepts

### Memory Files (CLAUDE.md / AGENTS.md)

These files provide persistent context that the AI reads at the start of every session:

- **Project-level** (`./CLAUDE.md`, `./AGENTS.md`): Shared with your team via git
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
| `/code-style` | Python code style guidelines |
| `/testing` | pytest conventions |
| `/git-workflow` | Git and commit conventions |
| `/llm-development` | LLM/ML best practices |

### Subagents

Subagents run specialized tasks in their own context window, enabling parallel execution and context isolation:

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Review code as a senior engineer (readonly) |
| `test-writer` | Write comprehensive tests (proactive) |
| `doc-generator` | Generate documentation |
| `verifier` | Validate completed work (fast model) |

Use subagents by:
- Slash command: `/code-reviewer review my changes`
- Natural language: "use the verifier agent to confirm the feature is complete"

## Boris Cherny's Top Tips

### 1. Start in Plan Mode

For complex tasks, start in Plan mode:
- **Cursor**: Toggle plan mode in the UI
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
ChernyCode/
├── README.md
├── CLAUDE.md                      # Project memory for Claude Code
├── AGENTS.md                      # Agent instructions for Cursor
├── threads.md                     # Source material from Boris Cherny
│
├── .cursor/skills/                # Project-specific Cursor skills
│   ├── code-style/SKILL.md
│   ├── testing/SKILL.md
│   ├── git-workflow/SKILL.md
│   └── llm-development/SKILL.md
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
├── cursor_personal_skills/        # Install to ~/.cursor/skills-cursor/
│   ├── commit-push-pr/SKILL.md
│   ├── techdebt/SKILL.md
│   └── code-simplifier/SKILL.md
│
├── cursor_subagents/              # Install to ~/.cursor/agents/
│   ├── code-reviewer.md
│   ├── doc-generator.md
│   ├── test-writer.md
│   └── verifier.md
│
└── .cursor/agents/                # Project-specific Cursor subagents
    ├── code-reviewer.md
    ├── doc-generator.md
    ├── test-writer.md
    └── verifier.md
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

~/.cursor/
├── skills-cursor/
│   ├── commit-push-pr/SKILL.md
│   ├── techdebt/SKILL.md
│   └── code-simplifier/SKILL.md
└── agents/
    ├── code-reviewer.md
    ├── doc-generator.md
    ├── test-writer.md
    └── verifier.md
```

## Customization

### Edit Project Memory

Update `CLAUDE.md` and `AGENTS.md` with:
- Your project's purpose and architecture
- Coding standards specific to your team
- Common commands and workflows
- Known pitfalls (add these as you encounter them)

### Create New Skills

1. Create a directory: `~/.claude/skills/my-skill/`
2. Add `SKILL.md` with frontmatter and instructions
3. Invoke with `/my-skill`

### Create New Subagents

**For Claude Code:**
1. Create a file: `~/.claude/agents/my-agent.md`
2. Add frontmatter with `name`, `description`, `allowed-tools`
3. Add the agent's system prompt
4. Use by asking Claude to "use the my-agent agent"

**For Cursor:**
1. Create a file: `.cursor/agents/my-agent.md` (project) or `~/.cursor/agents/my-agent.md` (global)
2. Add YAML frontmatter with:
   - `name`: Unique identifier (lowercase, hyphens)
   - `description`: When to use (Agent reads this for auto-delegation)
   - `model`: `fast`, `inherit`, or specific model ID
   - `readonly`: Set to `true` for read-only operations
   - `is_background`: Set to `true` for background execution
3. Add the agent's prompt below the frontmatter
4. Invoke with `/my-agent` or mention naturally in your prompt

## Sources

Based on Boris Cherny's threads:
- [How I use Claude Code](https://readwise.io/reader/shared/01kgcamtex6zews0fvz94a8qg4)
- [Tips from the Claude Code team](https://readwise.io/reader/shared/01kgb6njjekq2hpxc0ycymbrcg/)

## License

MIT
