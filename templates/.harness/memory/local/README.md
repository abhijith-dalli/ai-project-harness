# Local Memory

This directory contains temporary and private session context. It should NOT be committed to version control.

## Structure

```
local/
└── sessions/        Temporary session continuity information
```

## What Goes Here

- Session progress tracking
- Temporary working notes
- In-progress task state
- Session-specific context that expires

## What Does NOT Go Here

- Architectural decisions (use `shared/decisions/`)
- Lessons learned (use `shared/lessons/`)
- Project facts (use `shared/project/`)
- Anything durable (use `shared/`)

## Gitignore

This directory should be in `.gitignore`:

```gitignore
.harness/memory/local/
```
