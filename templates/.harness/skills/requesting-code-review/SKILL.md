---
name: requesting-code-review
description: >
  Use before merging code to request a thorough review. Prepares the
  review context, identifies what to review, and dispatches a reviewer
  subagent with clear instructions.
---

# Requesting Code Review

Prepare and dispatch a code review with clear context and specific review areas. A good review request saves reviewer time and catches more issues.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Before merging a feature branch
- After completing a significant change
- When changes affect multiple components
- When changes involve security-sensitive code
- When the task was complex or risky

## Pre-Review Checklist

Before requesting review, verify yourself:

- [ ] All tests pass
- [ ] Code follows project conventions
- [ ] No debug code or console.logs left
- [ ] Documentation updated if needed
- [ ] Commit messages are clear
- [ ] Self-review completed

## Review Request Format

```markdown
## Code Review Request

### What Changed
Brief description of the changes and why.

### Files Changed
- `path/to/file1.js` — what changed and why
- `path/to/file2.js` — what changed and why

### How to Verify
Steps the reviewer should take to verify the changes.

### Specific Review Areas
- [ ] Security implications
- [ ] Performance impact
- [ ] Edge cases
- [ ] Error handling
- [ ] Test coverage

### Context
Any background the reviewer needs to understand the changes.

### Concerns
Known issues or areas of uncertainty.
```

## Dispatching a Reviewer

When dispatching a reviewer subagent:

1. **Provide the review request** — formatted as above
2. **Include relevant memory** — past decisions, conventions, lessons
3. **Specify review focus** — what areas need the most attention
4. **Set expectations** — what a good review looks like

## Review Dimensions

Ask the reviewer to evaluate:

1. **Correctness** — does the code do what it's supposed to?
2. **Maintainability** — is the code easy to understand and modify?
3. **Security** — are there any security vulnerabilities?
4. **Performance** — are there any performance concerns?
5. **Tests** — are the tests adequate and correct?

## Rules

1. **Self-review first** — don't waste reviewer time on obvious issues
2. **Be specific** — tell the reviewer what to focus on
3. **Provide context** — the reviewer may not know the full story
4. **Be open to feedback** — reviews are about the code, not you
5. **Act on feedback** — don't just acknowledge, actually fix the issues
