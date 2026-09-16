---
name: executing-plans
description: >
  Use when a plan exists and you need to execute it. Batch execution with
  review checkpoints — load plan, review critically, execute tasks, report complete.
  Fallback when subagent-driven development is unavailable.
---

# Executing Plans

Batch execution with review checkpoints. Load plan, review critically, execute tasks, report complete. This is the fallback when subagent-driven development is unavailable.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- When a plan exists
- When subagents are unavailable
- When working in a separate session
- For straightforward task execution

## Process

### 1. Load the Plan
- Read the plan file completely
- Understand all tasks and dependencies
- Verify the plan is complete

### 2. Review Critically
- Are tasks truly independent?
- Are verification steps clear?
- Are file paths correct?
- Are there missing steps?

### 3. Execute Tasks
- Work through tasks in order
- Follow TDD where specified
- Verify each task before moving to the next
- Commit after each task

### 4. Report Completion
- Verify all tasks are done
- Run the full test suite
- Report what was accomplished
- Note any deviations from the plan

## Execution Rules

### Task Execution
1. Read the task completely before starting
2. Write the failing test first (if TDD specified)
3. Implement the minimal code to pass
4. Verify the implementation works
5. Commit with a meaningful message
6. Move to the next task

### Review Checkpoints
- After every 3-5 tasks, pause and review
- Check that work is on track
- Verify tests are passing
- Note any deviations

### Handling Issues
- If a task is blocked, skip it and continue
- If a task is wrong, document the issue
- If the plan is wrong, stop and reassess

## Output Format

```yaml
execution:
  plan: "path/to/plan.md"
  tasks_completed:
    - task: "Task 1: [Name]"
      status: "DONE"
      files_changed:
        - "path/to/file.js"
      commit: "abc1234"
    - task: "Task 2: [Name]"
      status: "DONE"
      files_changed:
        - "path/to/other.js"
      commit: "def5678"
  tasks_failed:
    - task: "Task 3: [Name]"
      status: "BLOCKED"
      reason: "dependency not available"
  deviations:
    - "deviation from plan: reason"
  test_results:
    total: 10
    passed: 10
    failed: 0
  recommendation: "plan executed successfully"
```

## Rules

1. **Follow the plan** — execute tasks as specified
2. **Verify each task** — don't skip verification
3. **Commit after each task** — meaningful commit messages
4. **Report deviations** — if you deviate from the plan, document why
5. **Run full test suite** — at the end, verify everything works
6. **Save execution results** — to memory for future reference
