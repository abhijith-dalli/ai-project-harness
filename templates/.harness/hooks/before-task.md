# Before Task Hook

**Lifecycle event:** `before-task`
**When:** Before starting work on a specific task
**Purpose:** Recall task-relevant memory and set context

## Actions

1. **Recall task-relevant memory** — search for related decisions, lessons, observations
2. **Load project conventions** — ensure awareness of project standards
3. **Check for related work** — see if similar tasks were done before
4. **Identify risks** — recall known pitfalls or constraints

## Provider Mapping

| Provider | Real Hook Event |
|----------|----------------|
| Claude Code | `PreToolUse` (with task detection) |
| OpenCode | `chat.message` (with task detection) |
| Cursor | `beforeSubmitPrompt` |
| Codex | `PreToolUse` |

## Memory Recall Strategy

```yaml
recall:
  - search: ".harness/memory/shared/decisions/"
    query: "related architectural decisions"
  - search: ".harness/memory/shared/lessons/"
    query: "relevant debugging lessons"
  - search: ".harness/memory/shared/observations/"
    query: "observations about this area"
```
