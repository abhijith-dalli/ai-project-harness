---
name: receiving-code-review
description: >
  Use when processing code review feedback. Evaluates feedback
  technically, responds with evidence, and implements changes
  without defensiveness.
---

# Receiving Code Review

Process code review feedback with technical rigor, not emotional response. A review is about the code, not about you.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- After receiving review feedback
- When review comments need resolution
- When disagreements about approach arise
- When review identifies issues to fix

## Processing Feedback

### Step 1: Read Everything First
- Read ALL comments before responding to any
- Understand the overall review theme
- Identify patterns in the feedback

### Step 2: Categorize Feedback

| Category | Action |
|----------|--------|
| Bug found | Fix immediately |
| Improvement suggestion | Evaluate and decide |
| Style preference | Follow project convention |
| Question | Answer with evidence |
| Disagreement | Discuss with evidence |

### Step 3: Respond to Each Comment

For each review comment:
1. **Understand** — what is the reviewer actually saying?
2. **Evaluate** — is the feedback technically correct?
3. **Decide** — fix, explain, or discuss
4. **Implement** — make the changes
5. **Respond** — explain what you did and why

## Handling Disagreements

When you disagree with review feedback:

1. **Assume good intent** — the reviewer wants better code
2. **Ask for clarification** — "Can you explain why you prefer X over Y?"
3. **Present evidence** — benchmarks, documentation, examples
4. **Propose alternatives** — "How about Z instead?"
5. **Escalate if needed** — involve a third party for tie-breaking

## Response Format

```markdown
## Review Response

### Changes Made
- Fixed: [description of fix]
- Improved: [description of improvement]

### Discussion Points
- [comment]: [your response with evidence]

### Remaining Questions
- [question for reviewer]
```

## Common Review Patterns

### "This could be simpler"
- Show the simpler approach
- Explain why the current approach was chosen
- If simpler is genuinely better, adopt it

### "This might have performance issues"
- Provide benchmarks or analysis
- Explain the performance characteristics
- If concern is valid, optimize

### "This needs tests"
- Add the requested tests
- Explain existing test coverage if adequate
- If coverage is genuinely adequate, explain why

## Rules

1. **No emotional responses** — this is about code quality
2. **Respond with evidence** — not opinions
3. **Fix what's broken** — don't argue about clear issues
4. **Discuss what's debatable** — with evidence and alternatives
5. **Learn from patterns** — if the same feedback appears twice, change your approach
