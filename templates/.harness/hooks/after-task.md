# After Task Hook

**Lifecycle event:** `after-task`
**When:** After completing work on a specific task
**Purpose:** Capture important findings and update project memory

## Actions

1. **Evaluate findings** — did this task produce important knowledge?
2. **Save decisions** — if architectural or technical decisions were made
3. **Save lessons** — if something was learned that future work should know
4. **Save observations** — if useful discoveries were made
5. **Update project context** — if project facts changed

## Memory Save Decision Tree

```
Did this task produce durable knowledge?
├── YES → Is it specific to this project?
│   ├── YES → Is it useful to future work?
│   │   ├── YES → Save to appropriate memory dir
│   │   └── NO → Skip
│   └── NO → Skip (not project-specific)
└── NO → Skip (temporary/noise)
```

## Provider Mapping

| Provider | Real Hook Event |
|----------|----------------|
| Claude Code | `PostToolUse` |
| OpenCode | `message.part.updated` |
| Cursor | `postToolUse` |
| Codex | `PostToolUse` |

## What to Save

| Type | When | Where |
|------|------|-------|
| Decision | Architecture/tech choice made | `shared/decisions/` |
| Lesson | Bug fix insight, mistake learned | `shared/lessons/` |
| Observation | Code pattern, behavior discovered | `shared/observations/` |

## What NOT to Save

- Passwords, API keys, tokens
- Routine tool output
- Temporary debugging noise
- Duplicate knowledge
- Raw conversation dumps
