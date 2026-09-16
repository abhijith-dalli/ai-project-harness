---
name: verifying-before-completion
description: >
  Use before claiming any task is complete. Requires actual evidence
  of correctness — no "should work" or "probably fine". Must run
  verification commands and show output.
---

# Verifying Before Completion

The iron law: no completion claims without fresh verification evidence. "Should work" and "probably fine" are not acceptable.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Before marking any task as done
- Before reporting completion to the user
- Before merging code
- Before deploying
- Before handing off to another agent

## Iron Law

**No completion claims without fresh verification evidence.**

You must actually run the verification and show the output. Thinking it should work is not evidence.

## Verification Process

### Step 1: Identify What to Verify
- What does "done" mean for this task?
- What tests should pass?
- What behavior should be observed?
- What commands prove correctness?

### Step 2: Run Verification
```bash
# Always run the actual commands
npm test
pytest
cargo test
go test ./...
```

### Step 3: Show Evidence
```bash
# Include the actual output
$ npm test

> project@1.0.0 test
> jest

PASS  src/utils.test.js
  ✓ should add numbers (2ms)
  ✓ should subtract numbers (1ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
```

### Step 4: Verify Completeness
- [ ] All tests pass
- [ ] No lint errors
- [ ] No type errors
- [ ] Feature works as specified
- [ ] No regressions in related areas

## What Counts as Evidence

| Evidence Type | Acceptable | Not Acceptable |
|---------------|------------|----------------|
| Test output | Full test run output | "Tests should pass" |
| Lint output | Full lint run output | "No lint errors" |
| Type check | Full type check output | "Types look correct" |
| Manual test | Steps + screenshots/output | "I tested it" |
| Code review | Reviewer approval | "Looks good to me" |

## Completion Report Format

```markdown
## Task Complete: [Task Name]

### Verification Evidence
[Actual command output]

### What Was Done
- [change 1]
- [change 2]

### Files Changed
- `path/to/file.js` — [what changed]

### Tests
- [test name] — [pass/fail]

### Concerns
- [any concerns or limitations]
```

## Rules

1. **Show, don't tell** — actual output, not claims
2. **Run the full suite** — not just the test you wrote
3. **Verify what matters** — focus on the acceptance criteria
4. **Be honest** — if something doesn't work, say so
5. **No "should" or "probably"** — either it works or it doesn't
