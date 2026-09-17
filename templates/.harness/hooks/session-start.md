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

## Runtime Recording

Record this event to `.harness/data/events.jsonl` by appending a JSON line:

```json
{"timestamp": "<ISO-8601>", "event": "SESSION_STARTED", "execution_id": "<if available>", "session_id": "<if available>"}
```

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

# Record session start event
DATA_DIR="$HARNESS_DIR/data"
mkdir -p "$DATA_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STARTED\"}" >> "$DATA_DIR/events.jsonl"
```
