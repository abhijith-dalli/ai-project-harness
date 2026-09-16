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

| Logical Event | Claude Code Hook | Script |
|---|---|---|
| session-start | `SessionStart` | `hooks/session-start.mjs` |
| before-task | `PreToolUse` (with detection) | `hooks/pre-tool-use.mjs` |
| after-task | `PostToolUse` | `hooks/post-tool-use.mjs` |
| before-commit | `PreToolUse` (Write/Edit) | `hooks/pre-tool-use.mjs` |

Additional Claude Code hooks (from agentmemory):
- `UserPromptSubmit` — capture user prompt context
- `PreCompact` — snapshot before context compaction
- `SubagentStart` / `SubagentStop` — track subagent lifecycle
- `Stop` / `SessionEnd` — session summary and consolidation

### OpenCode

| Logical Event | OpenCode Hook | Handler |
|---|---|---|
| session-start | `session.created` | Session initialization |
| before-task | `chat.message` | Message processing |
| after-task | `message.part.updated` | Part completion |
| before-commit | `file.edited` | File change detection |

OpenCode provides 22 auto-capture hooks covering:
- Session lifecycle (created, idle, status, compacted, updated, deleted, error)
- Messages (chat.message, message.updated, message.removed)
- Parts/steps (subtask, tool, error, step-finish, reasoning, patch)
- File enrichment (tool.execute.before, file.edited)
- Permissions (permission.updated, permission.replied)
- Tasks (todo.updated, command.executed)

### Cursor

| Logical Event | Cursor Hook | Script |
|---|---|---|
| session-start | `sessionStart` | `session-start.mjs` |
| before-task | `beforeSubmitPrompt` | `prompt-submit.mjs` |
| after-task | `postToolUse` | `post-tool-use.mjs` |
| before-commit | `preToolUse` | `pre-tool-use.mjs` |

Additional Cursor hooks:
- `stop` — session summary
- `sessionEnd` — final consolidation

### Codex CLI

| Logical Event | Codex Hook | Script |
|---|---|---|
| session-start | `SessionStart` | `session-start.mjs` |
| before-task | `PreToolUse` | `pre-tool-use.mjs` |
| after-task | `PostToolUse` | `post-tool-use.mjs` |
| before-commit | `PreToolUse` (Write/Edit) | `pre-tool-use.mjs` |

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
  - Link commit to session (if agentmemory enabled)
```

## Agentmemory Lifecycle Hooks

When agentmemory is enabled, additional hooks are available:

| Hook | Purpose |
|---|---|
| `SessionStart` | Register session, inject memory context |
| `UserPromptSubmit` | Capture user prompt, detect project |
| `PreToolUse` | Inject file-specific memory context |
| `PostToolUse` | Record tool result as observation |
| `PostToolUseFailure` | Record failed tool attempts |
| `PreCompact` | Snapshot before context compaction |
| `SubagentStart` | Track subagent spawning |
| `SubagentStop` | Record subagent results |
| `Stop` | Summarize session, run consolidation |
| `SessionEnd` | Finalize session, fire graph extraction |

These hooks are optional and managed by the agentmemory adapter, not the core harness.

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
