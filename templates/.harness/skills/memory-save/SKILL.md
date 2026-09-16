---
name: memory-save
description: >
  Use after completing important work to persist decisions, lessons, and
  observations to project memory. Ensures future sessions and agents can
  benefit from current work context.
---

# Memory Save

Persist important decisions, lessons, and observations to project memory. This skill ensures that valuable knowledge is captured for future sessions and agents.

## When to Use

- After making an important architectural decision
- After debugging a non-obvious issue
- After discovering something useful about the codebase
- After completing a significant feature
- After learning a lesson the hard way

## Memory Quality Test

Before saving, ask:

1. **Is it durable?** — will this still be relevant in a month?
2. **Is it useful to future work?** — would another agent benefit from this?
3. **Is it specific to this project?** — not generic advice
4. **Is it not already represented?** — check for duplicates
5. **Is it important enough to persist?** — not routine information

If the answer to any question is "no," do not save.

## Process

1. **Identify what to save** — decisions, lessons, or observations
2. **Check for existing memory** — search before saving to avoid duplicates
3. **Choose the right location:**
   - `decisions/` — architectural and technical decisions
   - `lessons/` — mistakes, debugging findings, reusable knowledge
   - `observations/` — useful discoveries about the codebase
   - `project/` — stable project facts and conventions
4. **Write the memory file** with proper YAML frontmatter
5. **If agentmemory is enabled** — also save via MCP tools:
   - `memory_save` — save to agentmemory backend

## Memory File Format

```markdown
---
type: decision|lesson|observation|project
topic: "brief topic description"
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# [Title]

## Context
Why this was recorded.

## Content
The actual knowledge.

## Implications
How this affects future work.
```

## File Naming

Use descriptive kebab-case filenames with numeric prefixes for ordering:

```
001-database-choice.md
002-pdf-rendering-approach.md
003-authentication-flow.md
```

## Supported States

| State | Meaning |
|-------|---------|
| `active` | Current and relevant — use as truth |
| `superseded` | Replaced by newer information — do not use |
| `deprecated` | No longer relevant — keep for history |
| `archived` | Historical record — do not use for decisions |

## Where to Save

### decisions/
Architectural and technical decisions. Include:
- What was decided
- Why it was decided
- Alternatives considered
- Trade-offs accepted

### lessons/
Mistakes, debugging findings, reusable knowledge. Include:
- What went wrong
- Root cause
- How it was fixed
- How to prevent it in the future

### observations/
Useful discoveries about the codebase. Include:
- What was observed
- Where it was observed
- Why it matters
- How it affects future work

### project/
Stable project facts and conventions. Include:
- Technology stack
- Architecture patterns
- Coding conventions
- Testing conventions

## Rules

1. **Never save secrets** — no API keys, passwords, tokens
2. **Never save routine information** — only durable, useful knowledge
3. **Never duplicate** — check existing memory before saving
4. **Always use proper format** — YAML frontmatter with required fields
5. **Always use descriptive names** — filenames should be self-explanatory
6. **Update existing memory** — if equivalent memory exists, update it
7. **Mark superseded memory** — don't delete, mark as superseded
