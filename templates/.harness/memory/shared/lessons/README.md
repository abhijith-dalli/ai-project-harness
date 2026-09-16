# Lessons

Mistakes, debugging insights, and reusable findings from development.

## What to Store Here

- Bug fix insights (root cause, not just symptoms)
- Common mistakes to avoid
- Performance pitfalls
- Integration gotchas
- Testing insights

## File Format

```yaml
---
type: lesson
topic: brief-topic-slug
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

```markdown
# Lesson: [Title]

## What Happened
Description of the issue or mistake.

## Root Cause
The actual underlying cause.

## What Was Learned
The reusable insight.

## How to Prevent
Steps to avoid this in the future.

## Evidence
Links to commits, issues, or code that demonstrate the lesson.
```

## Naming Convention

```
001-n+1-query-pattern.md
002-cors-configuration.md
003-memory-leak-cause.md
```
