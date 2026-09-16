# Before Commit Hook

**Lifecycle event:** `before-commit`
**When:** Before committing code changes
**Purpose:** Verify quality and capture commit context

## Actions

1. **Run verification** — tests, lint, type check
2. **Review changes** — what was actually changed?
3. **Check for secrets** — ensure no credentials are committed
4. **Save commit context** — if agentmemory is enabled, link commit to session
5. **Update memory** — if the commit resolves an issue or makes a decision

## Provider Mapping

| Provider | Real Hook Event |
|----------|----------------|
| Claude Code | `PreToolUse` (Write/Edit detection) |
| OpenCode | `file.edited` + `todo.updated` |
| Cursor | `preToolUse` |
| Codex | `PreToolUse` |

## Pre-Commit Checklist

```bash
# Verification commands (adapt to project)
npm test           # or pytest, cargo test, go test
npm run lint       # or ruff, clippy, golint
npm run typecheck  # or mypy, tsc --noEmit
```

## Security Check

Ensure these are NOT in the diff:
- API keys or tokens
- Passwords
- Private keys
- `.env` file contents
- Database credentials

## Commit Context

If agentmemory is enabled, the before-commit hook can:
- Link the commit to the current agent session
- Record which task was being worked on
- Capture the reasoning behind the changes
