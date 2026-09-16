---
name: subagent-driven-development
description: >
  Use for executing implementation plans with fresh subagents per task.
  Each task gets a dedicated subagent with a clean context, two-stage
  review (spec compliance then code quality), and ledger tracking.
---

# Subagent-Driven Development

Execute plans with fresh subagents per task. Each subagent gets a clean context focused on one task, avoiding context pollution from previous work.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Executing a multi-task implementation plan
- When tasks are independent enough for fresh contexts
- When context pollution is a concern
- For medium to large implementation efforts

## Process

### 1. Setup
- Load the implementation plan
- Create a worktree if needed
- Initialize progress ledger
- Read project memory and conventions

### 2. Task Loop

For each task in the plan:

#### Dispatch Implementer
```
You are implementing a specific task in a larger plan.

PROJECT CONTEXT:
[relevant project memory]

PLAN:
[full plan or relevant section]

YOUR TASK:
[specific task with exact file paths and instructions]

CONSTRAINTS:
- Follow existing patterns
- Write tests first (TDD)
- Self-review before reporting
```

#### Implementer Executes
- Reads the codebase
- Implements the task
- Writes tests
- Self-reviews

#### Review Task
Two-stage review:

**Stage 1: Spec Compliance**
- Does the implementation match the spec?
- Is anything missing?
- Is anything extra?

**Stage 2: Code Quality**
- Is the code clean and maintainable?
- Are there any issues?
- Does it follow project conventions?

#### Handle Report
- If PASS → mark task complete, proceed to next
- If FAIL → fix issues, re-review (max 5 rounds per task)

### 3. Final Review
- Review the entire branch on the most capable model
- Check for integration issues
- Verify all tasks are complete

### 4. Finish
- Clean up worktree if created
- Run full test suite
- Present completion report

## Progress Ledger

Track progress in `.harness/memory/local/sessions/progress.md`:

```markdown
# Implementation Progress

## Task 1: [Name]
Status: DONE
Files: [list]
Notes: [any concerns]

## Task 2: [Name]
Status: IN_PROGRESS
Files: [list]
Notes: [blocking issue]
```

## Fix Loop

If a task fails review:

1. **Rounds 1-3:** Resume the same implementer with feedback
2. **Rounds 4-5:** Fresh implementer with more context
3. **Round 5+:** Escalate — the task may need decomposition

## Rules

1. **Fresh context per task** — don't let previous tasks pollute current
2. **Two-stage review** — spec compliance THEN code quality
3. **Max 5 rounds** — if a task can't be done in 5 rounds, decompose it
4. **Ledger tracking** — always know what's done and what's pending
5. **Final whole-branch review** — catch integration issues
