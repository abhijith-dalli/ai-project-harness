# Memory Architecture

The harness provides a canonical, provider-independent memory system that works with or without the optional agentmemory backend.

## Architecture

```
.harness/memory/
├── shared/                     ← COMMITTED (durable project knowledge)
│   ├── project/                Stable project facts and conventions
│   ├── decisions/              Architectural and technical decisions
│   ├── lessons/                Mistakes, debugging lessons
│   └── observations/           Useful discoveries
└── local/                      ← GITIGNORED (temporary session context)
    └── sessions/               Session progress and working notes
```

## Shared Memory (Committed)

### project/

Stable project facts that don't change frequently:
- Technology stack
- Coding conventions
- Architecture overview
- Deployment details

### decisions/

Architectural and technical decisions:
```yaml
---
type: decision
topic: database-choice
status: active
created: 2026-09-17
---
```

### lessons/

Mistakes and debugging insights:
```yaml
---
type: lesson
topic: n+1-query
status: active
created: 2026-09-17
---
```

### observations/

Useful discoveries that aren't decisions or lessons:
```yaml
---
type: observation
topic: cache-behavior
status: active
created: 2026-09-17
---
```

## Local Memory (Gitignored)

Temporary session context:
- Progress tracking
- Working notes
- In-progress state

## File Format

### YAML Frontmatter

```yaml
---
type: decision | lesson | observation
topic: kebab-case-slug
status: active | superseded | deprecated | archived
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Naming Convention

```
001-database-choice.md
002-authentication-pattern.md
```

Numeric prefix for ordering, kebab-case for readability.

## Memory States

| State | Meaning | Usage |
|---|---|---|
| active | Current truth | Use for decisions |
| superseded | Replaced by newer info | Mark old decisions |
| deprecated | No longer relevant | Archive old patterns |
| archived | Historical reference | Keep for context |

## Quality Rules

Before saving, ask:
1. **Is it durable?** Will this be true next week?
2. **Is it useful?** Will someone else need this?
3. **Is it project-specific?** Not generic advice
4. **Is it not duplicate?** No existing equivalent
5. **Is it important enough?** Not noise

## Cross-Agent Sharing

All agents working on the same project share `.harness/memory/shared/`:

```
                 ┌── Claude Code
                 │
     Agent ──────┼── OpenCode
                 │
                 └── Cursor
                       │
                       ▼
              .harness/memory/shared/
```

Provider caches are implementation details, not sources of truth.

## agentmemory Integration (Optional)

When agentmemory is enabled:
- `.harness/memory/shared/` remains the canonical source
- agentmemory provides an optional advanced backend
- MCP tools enable search: `memory_smart_search`, `memory_recall`
- Lifecycle hooks auto-capture session context

When agentmemory is disabled:
- File-based memory works independently
- No server required
- All agents can read/write markdown files

## Project Isolation

Each project has its own `.harness/memory/`:

```
TaxSystem/.harness/memory/
RecruitmentSystem/.harness/memory/
OESSystem/.harness/memory/
```

Memory from one project never leaks into another.

If agentmemory is enabled, project isolation uses the `project` field resolved from:
1. `AGENTMEMORY_PROJECT_NAME` env var
2. Git repo basename
3. Directory basename

## What to Persist

| Type | Persist? | Location |
|---|---|---|
| Architecture decisions | Yes | shared/decisions/ |
| Bug fix insights | Yes | shared/lessons/ |
| Code patterns | Yes | shared/observations/ |
| Project conventions | Yes | shared/project/ |
| API keys/tokens | NEVER | — |
| Raw conversation | No | — |
| Temporary debugging | No | — |
| Duplicate knowledge | No | update existing |
