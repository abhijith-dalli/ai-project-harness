# Hooks

Lifecycle hooks and their provider-specific implementations.

## Logical Lifecycle Events

The harness defines four core lifecycle events:

| Event | When | Purpose |
|---|---|---|
| session-start | AI session begins | Load project context, recall memory |
| before-task | Starting work on a task | Recall task-relevant memory |
| after-task | Completing a task | Save important findings |
| before-commit | Before committing code | Verify quality, capture context |

## Provider Mapping

### Claude Code

| Logical Event | Claude Code Hook |
|---|---|
| session-start | `SessionStart` |
| before-task | `PreToolUse` (with task detection) |
| after-task | `PostToolUse` |
| before-commit | `PreToolUse` (Write/Edit) |

Additional Claude Code hooks:
- `UserPromptSubmit` — capture user prompt context
- `PreCompact` — snapshot before context compaction
- `SubagentStart` / `SubagentStop` — track subagent lifecycle
- `Stop` / `SessionEnd` — session summary and consolidation

### OpenCode

| Logical Event | OpenCode Hook |
|---|---|
| session-start | `session.created` |
| before-task | `chat.message` |
| after-task | `message.part.updated` |
| before-commit | `file.edited` |

### Cursor

| Logical Event | Cursor Hook |
|---|---|
| session-start | `sessionStart` |
| before-task | `beforeSubmitPrompt` |
| after-task | `postToolUse` |
| before-commit | `preToolUse` |

Additional Cursor hooks:
- `stop` — session summary
- `sessionEnd` — final consolidation

### Codex CLI

| Logical Event | Codex Hook |
|---|---|
| session-start | `SessionStart` |
| before-task | `PreToolUse` |
| after-task | `PostToolUse` |
| before-commit | `PreToolUse` (Write/Edit) |

## Hook Implementation

### session-start

```yaml
purpose: Load project context and recall relevant memory
actions:
  - Read .harness/project-context.md
  - Search .harness/memory/shared/ for current context
  - Check harness version compatibility
  - Load enabled skills
```

### before-task

```yaml
purpose: Recall task-relevant memory before starting work
actions:
  - Search decisions/ for related architectural choices
  - Search lessons/ for relevant debugging insights
  - Search observations/ for related discoveries
  - Load project conventions
```

### after-task

```yaml
purpose: Capture important findings after completing work
decision_tree:
  - Did this task produce durable knowledge?
    - YES → Is it project-specific?
      - YES → Is it useful to future work?
        - YES → Save to appropriate memory directory
        - NO → Skip
      - NO → Skip
    - NO → Skip
save_locations:
  - decisions/ — architectural/technical choices
  - lessons/ — bug fixes, mistakes learned
  - observations/ — code patterns, discoveries
```

### before-commit

```yaml
purpose: Verify quality and capture commit context
actions:
  - Run tests, lint, type check
  - Review changes in diff
  - Check for secrets/credentials
```

## Hook Limitations

Not all providers support all lifecycle events:

| Event | Claude Code | OpenCode | Cursor | Codex |
|---|---|---|---|---|
| session-start | ✅ | ✅ | ✅ | ✅ |
| before-task | ✅ | ✅ | ✅ | ✅ |
| after-task | ✅ | ✅ | ✅ | ✅ |
| before-commit | ✅ | ✅ | ✅ | ✅ |
| pre-compact | ✅ | ✅ | ❌ | ❌ |
| subagent-track | ✅ | ✅ | ❌ | ❌ |

When a provider doesn't support a hook event, the harness documents the limitation and uses the closest available mechanism.
