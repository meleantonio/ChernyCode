# Project Memory - ChernyCode

This is a **config-only template repo** (no application code) with AI-assisted coding workflows inspired by Boris Cherny's Claude Code tips. Coding standards below are for projects that adopt this template, not for this repo itself.

## Project Purpose

This project serves as a template and reference implementation for optimizing AI-assisted coding workflows with Claude Code and VS Code. It contains:
- Memory files (CLAUDE.md)
- Custom skills and commands
- Subagent configurations

## Coding Standards

### Python
- **Version**: Python 3.10+
- **Formatter**: Ruff (replaces black, isort, flake8)
- **Testing**: pytest with 80%+ coverage
- **Type hints**: Required for all functions
- **Docstrings**: Google-style
- **Naming**: snake_case for functions/variables, PascalCase for classes

### Deployment & Infrastructure
- **Prefer Cloudflare** for hosting and infrastructure where it makes sense:
  - Cloudflare Workers for serverless functions and API endpoints
  - Cloudflare Pages for static sites and frontend deployments
  - Cloudflare Workers Scripts for automation and scheduled tasks
  - Cloudflare D1, KV, R2 for data storage needs
- Evaluate Cloudflare-first before reaching for AWS, GCP, or Vercel

### TypeScript (Cloudflare Workers)
- **Strict mode** enabled — no implicit `any`
- Prefer `const` over `let`; avoid `var`
- Use `wrangler` for local dev (`wrangler dev`) and deployment (`wrangler deploy`)
- Use Cloudflare Workers Secrets (`wrangler secret put`) for sensitive config
- Naming: camelCase for functions/variables, PascalCase for types/interfaces

### General
- Indentation: 4 spaces
- Max line length: 120 characters
- Error handling: Try-except with logging
- Use structured logging with `structlog`

### Security & Secrets
- **Never commit** `.env` files, API keys, tokens, or credentials
- Use platform-native secrets management (Cloudflare Secrets, GitHub Secrets)
- Flag any hardcoded secrets found during code review
- Add sensitive file patterns to `.gitignore` before starting work

### Dependency Management
- Prefer minimal dependencies — vet new packages before adding
- Always use lockfiles (`package-lock.json`, `poetry.lock`) and commit them
- Pin major versions to avoid breaking changes

### Scope Discipline
- Don't add features, refactoring, or "improvements" beyond what was asked
- Ask before making large architectural changes
- One PR = one concern — don't bundle unrelated changes

### Context Gathering
- Read relevant code before modifying it
- Check `git log` / `git blame` for recent changes in the area being modified
- Look for existing patterns in the codebase before inventing new ones

### Documentation
- **Proactively create and maintain documentation as features are built** — don't leave it for later
- Update README when adding features, changing setup steps, or modifying architecture
- Document API endpoints, configuration options, and environment variables as they are created
- Inline comments only where logic isn't self-evident — don't over-comment
- PR descriptions should explain the "why", not just the "what"
- Add usage examples for new utilities, scripts, or CLI commands
- Keep architecture docs current — if the system design changes, update the docs in the same PR

## Claude Code Skills & Plugins

- At the start of each session, review available skills and plugins (slash commands, subagents, MCP servers)
- **Use skills and plugins as frequently as needed** — they exist to improve quality and efficiency, not as a last resort
- Proactively invoke relevant skills for code review, testing, commits, PRs, debugging, and planning
- When in doubt whether a skill applies, invoke it — it's better to check than to skip

## Maintaining CLAUDE.md

- **Keep per-project CLAUDE.md files updated as the project evolves** — treat them as living documents, not static setup
- When new patterns, conventions, pitfalls, or architecture decisions emerge during development, add them immediately
- When files/directories are added or renamed, update the Key Files section
- When a mistake is made and corrected, add it to Known Pitfalls so it doesn't recur
- When new tools, commands, or workflows are established, document them in Common Workflows
- Proactively suggest CLAUDE.md updates at the end of sessions where significant work was done

## Common Workflows

### Git Workflow
- **All changes must be made in feature branches with Pull Requests** — never commit directly to main
- Follow GitHub Flow (feature branches from main)
- Every change goes through: branch → commit → push → PR → review → merge
- Use Conventional Commits format:
  - `feat:` new feature
  - `fix:` bug fix
  - `docs:` documentation
  - `refactor:` code refactoring
  - `test:` adding tests
  - `chore:` maintenance

### Testing
- Run tests with: `pytest`
- Run with coverage: `pytest --cov`
- Always run tests before committing

### Code Quality
- Format code: `ruff format .`
- Lint code: `ruff check .`
- Fix linting issues: `ruff check --fix .`

## Key Files

- `CLAUDE.md` - This file, Claude Code memory
- `setup.sh` - One-time environment bootstrap for new machines
- `idea.sh` - Interactive new project scaffolding script
- `standardize.sh` - Bring existing projects inline with standards
- `claude_personal_skills/` - Claude Code personal skills (code-simplifier, commit-push-pr, techdebt)
- `claude_subagents/` - Claude Code subagent definitions (code-reviewer, doc-generator, test-writer)
- `.github/CODEOWNERS` - Code ownership for PR reviews
- `threads.md` - Source material from Boris Cherny

## Known Pitfalls

- No Python code exists in this repo — don't attempt to run `pytest`, `ruff`, or other code tools here
- Claude skills are defined in `SKILL.md` files within skill directories
- The global `~/.claude/CLAUDE.md` and this project `CLAUDE.md` have overlapping content — edits may need to be synced

## Verification

Before completing any task:
1. Verify markdown files render correctly (no broken links or formatting)
2. Ensure skill/subagent definitions follow their expected SKILL.md format
3. Check that CLAUDE.md stays consistent across global and project levels
4. For projects using this template: run test suite, linter, verify changes

---
*Update this file whenever Claude makes a mistake: "Update CLAUDE.md so you don't make that mistake again"*
