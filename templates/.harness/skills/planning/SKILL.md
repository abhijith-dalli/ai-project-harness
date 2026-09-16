---
name: planning
description: >
  Use when a task requires a detailed implementation plan before coding.
  Creates bite-sized tasks with exact file paths, complete code references,
  verification steps, and acceptance criteria.
---

# Planning

Detailed implementation plans with bite-sized tasks, exact file paths, verification steps, and acceptance criteria. Plans assume the implementer has zero context for the codebase.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- After brainstorming/design is approved
- For medium or large tasks
- When multiple files need changes
- When TDD is required

## Plan Principles

1. **Every task is 2-5 minutes** — bite-sized, not hour-long
2. **Every task has exact file paths** — no ambiguity about what to change
3. **Every task has verification** — how to confirm it works
4. **No placeholders** — every step must contain actual content
5. **TDD preferred** — test first, implementation second

## Plan Structure

```markdown
# Implementation Plan: [Feature Name]

## Overview
Brief description of what will be implemented.

## Global Constraints
- DRY — don't repeat yourself
- YAGNI — you ain't gonna need it
- TDD — test first, implementation second
- Follow existing patterns

## Interfaces
### Input
What this feature receives.

### Output
What this feature produces.

### Dependencies
What this feature depends on.

## Tasks

### Task 1: [Name]
**Files:** `path/to/file.js`
**Dependencies:** none
**Test:** `test/path/to/file.test.js`
**What to do:**
1. [specific instruction]
2. [specific instruction]
**How to verify:**
```bash
[verification command]
```

### Task 2: [Name]
**Files:** `path/to/other.js`
**Dependencies:** Task 1
**Test:** `test/path/to/other.test.js`
**What to do:**
1. [specific instruction]
**How to verify:**
```bash
[verification command]
```

## Risks
- [risk 1]: [mitigation]
- [risk 2]: [mitigation]

## Acceptance Criteria
- [ ] [criterion 1]
- [ ] [criterion 2]
```

## Self-Review Checklist

After writing the plan:
- [ ] Spec coverage — all requirements are addressed
- [ ] Placeholder scan — no "TBD", "TODO", or vague steps
- [ ] Type consistency — all file paths exist
- [ ] Verification steps — every task has a way to verify
- [ ] Test instructions — every task specifies what tests to write

## Execution Choice

After writing the plan, offer:
1. **Subagent-driven development** (recommended) — fresh subagent per task
2. **Inline execution** — execute tasks in current session

## Rules

1. **No placeholders** — every step must contain actual content
2. **Every task is small** — 2-5 minutes, not hours
3. **Every task is verifiable** — include specific verification steps
4. **Follow existing patterns** — reference existing code as examples
5. **Self-review** — check for completeness and consistency
6. **Save the plan** — to `.harness/memory/shared/decisions/` for reference
