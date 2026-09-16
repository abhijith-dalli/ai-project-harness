# Shared Memory

This directory contains durable project knowledge that should be committed to version control.

## Structure

```
shared/
├── project/          Stable project facts and conventions
├── decisions/        Architectural and technical decisions
├── lessons/          Mistakes, debugging lessons, reusable findings
└── observations/     Useful discoveries that are not decisions
```

## File Format

Each memory file uses YAML frontmatter:

```yaml
---
type: decision | lesson | observation
topic: brief-topic-slug
status: active | superseded | deprecated | archived
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Title

Content describing the memory.
```

## Naming Convention

Use kebab-case with numeric prefixes for ordering:

```
001-database-choice.md
002-authentication-pattern.md
001-validation-issue.md
```

## Quality Rules

Before saving, ask:
1. Is it durable? (will this be true next week?)
2. Is it useful to future work? (will someone else need this?)
3. Is it specific to this project? (not generic advice)
4. Is it not already represented? (no duplicates)
5. Is it important enough to persist? (not noise)

## States

- **active** — current truth, use for decisions
- **superseded** — replaced by newer information
- **deprecated** — no longer relevant
- **archived** — kept for historical reference
