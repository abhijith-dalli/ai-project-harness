---
name: systematic-debugging
description: >
  Use when investigating a bug, test failure, or unexpected behavior.
  Four-phase root cause investigation: root cause analysis, pattern
  tracing, hypothesis testing, and minimal fix implementation.
---

# Systematic Debugging

Structured bug investigation with root cause analysis before any fix attempts. The iron law: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- A test is failing
- A bug is reported
- Unexpected behavior occurs
- Performance degradation is observed
- Something worked before but doesn't now

## Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you skip root cause analysis, you will waste time on wrong hypotheses and potentially introduce new bugs.

## Four Phases

### Phase 1: Root Cause Investigation

1. **Reproduce the failure** — can you make it fail reliably?
2. **Read the error message** — what does it actually say?
3. **Check recent changes** — `git log`, `git diff`, `git blame`
4. **Read the failing code** — trace the execution path
5. **Check the test** — is the test correct? Does it test what you think?

### Phase 2: Pattern Analysis

1. **Is this a new pattern or recurring?** — search for similar failures
2. **Check related code** — are there similar bugs nearby?
3. **Check assumptions** — what assumptions does the code make?
4. **Check the environment** — configuration, dependencies, data

### Phase 3: Hypothesis Testing

1. **Form a hypothesis** — "The bug is caused by X because Y"
2. **Design a test** — what would confirm or refute this hypothesis?
3. **Run the test** — actually execute it
4. **Evaluate results** — does the evidence support the hypothesis?
5. **If not, form new hypothesis** — repeat until root cause is found

### Phase 4: Minimal Fix

1. **Make the smallest change** — that fixes the root cause
2. **Verify the fix** — run the original failing test
3. **Check for regressions** — run the full test suite
4. **Document the root cause** — save to `.harness/memory/shared/lessons/`

## Architecture Questioning

If 3+ fix attempts have failed:
- Question the architecture itself
- Is the design fundamentally flawed?
- Is there a structural issue causing multiple symptoms?
- Should the approach be redesigned rather than patched?

## Root Cause Tracing

### Defense in Depth
- What layers of defense exist?
- Which layer failed?
- Why did that layer fail?

### Condition-Based Waiting
- Is there a race condition?
- Is there a timing issue?
- Is there a missing dependency?

## Output Format

```markdown
## Debugging Report: [Issue]

### Reproduction
Steps to reproduce the failure.

### Root Cause
The actual root cause, with evidence.

### Fix
The minimal fix applied.

### Verification
Evidence that the fix works and no regressions occurred.

### Lesson Learned
What to remember for future reference (saved to lessons/).
```

## Rules

1. **Root cause first** — never skip investigation
2. **Reproduce before fixing** — if you can't reproduce it, you can't verify the fix
3. **Minimal changes** — fix the root cause, not symptoms
4. **Verify thoroughly** — run the full test suite, not just the failing test
5. **Document findings** — save important debugging lessons to project memory
