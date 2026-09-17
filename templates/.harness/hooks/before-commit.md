# Before Commit Hook

**Lifecycle event:** `before-commit`
**When:** Before committing code changes
**Purpose:** Verify quality and capture commit context

## Actions

1. **Run verification** — tests, lint, type check
2. **Review changes** — what was actually changed?
3. **Check for secrets** — ensure no credentials are committed

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

## Runtime Recording

Record these events to `.harness/data/events.jsonl` by appending JSON lines:

```json
{"timestamp": "<ISO-8601>", "event": "HOOK_STARTED", "hook": "before-commit", "execution_id": "<if available>"}
{"timestamp": "<ISO-8601>", "event": "VERIFICATION", "execution_id": "<if available>"}
```

If verification passes and commit proceeds:

```json
{"timestamp": "<ISO-8601>", "event": "COMMIT", "execution_id": "<if available>"}
```

If verification fails:

```json
{"timestamp": "<ISO-8601>", "event": "HOOK_FAILED", "hook": "before-commit", "error": "<error description>", "execution_id": "<if available>"}
```

## Security Check

Ensure these are NOT in the diff:
- API keys or tokens
- Passwords
- Private keys
- `.env` file contents
- Database credentials
