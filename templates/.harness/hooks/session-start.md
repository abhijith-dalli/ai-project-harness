# Session Start Hook

**Lifecycle event:** `session-start`
**When:** A new AI session begins in the project
**Purpose:** Load project context and recall relevant memory

## Actions

1. **Read project context** — load `.harness/project-context.md`
2. **Recall relevant memory** — search `.harness/memory/shared/` for current context
3. **Check harness version** — verify compatibility
4. **Load enabled skills** — initialize skill availability

## Provider Mapping

| Provider | Real Hook Event |
|----------|----------------|
| Claude Code | `SessionStart` |
| OpenCode | `session.created` |
| Cursor | `sessionStart` |
| Codex | `SessionStart` |

## Implementation

```bash
#!/bin/bash
# Session start hook — loads project context

HARNESS_DIR="$(dirname "$0")/../.."
CONTEXT_FILE="$HARNESS_DIR/project-context.md"

if [ -f "$CONTEXT_FILE" ]; then
  echo "Project context loaded from $CONTEXT_FILE"
fi

# Recall relevant memory (file-based, always available)
MEMORY_DIR="$HARNESS_DIR/memory/shared"
if [ -d "$MEMORY_DIR" ]; then
  echo "Project memory available at $MEMORY_DIR"
fi
```
