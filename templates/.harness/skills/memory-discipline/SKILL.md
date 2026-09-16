---
name: memory-discipline
description: >
  Codifies the session loop the memory model expects: recall before nontrivial
  work, save decisions with reasons, maintain memory quality. This skill
  governs when and how to interact with project memory.
---

# Memory Discipline

This skill codifies the session loop the memory model expects. It governs when and how to interact with project memory to maintain quality and usefulness.

## The Memory Loop

```
1. RECALL before nontrivial work
2. WORK with context from memory
3. SAVE important findings after work
4. MAINTAIN memory quality over time
```

## Recall Rules

### When to Recall

- **Always** before starting any nontrivial task
- **Always** when investigating a bug or issue
- **Always** before making architectural decisions
- **Always** when resuming work on a feature
- **Never** for trivial one-line changes

### How to Recall

1. Read `.harness/project-context.md` first
2. Read relevant files in `.harness/memory/shared/decisions/`
3. Read relevant files in `.harness/memory/shared/lessons/`
4. Check `.harness/memory/shared/observations/`

### What to Look For

- Existing decisions that affect current work
- Known pitfalls and debugging lessons
- Project conventions and patterns
- Related previous work
- Constraints and requirements

## Save Rules

### When to Save

- **Always** after making an important decision
- **Always** after debugging a non-obvious issue
- **Always** after discovering something useful
- **Never** for routine changes
- **Never** for temporary information

### What to Save

- **Decisions** — why something was chosen over alternatives
- **Lessons** — what went wrong and how it was fixed
- **Observations** — useful facts about the codebase
- **Project facts** — stable conventions and patterns

### What NOT to Save

- Passwords, API keys, tokens, or secrets
- Raw conversation dumps
- Routine tool output
- Temporary debugging noise
- Duplicate knowledge
- Generic advice (must be project-specific)

## Memory Quality Standards

### Before Saving

1. Is it durable? (relevant in a month)
2. Is it useful to future work? (another agent would benefit)
3. Is it specific to this project? (not generic)
4. Is it not already represented? (check for duplicates)
5. Is it important enough? (not routine)

### After Saving

1. Verify the file was created correctly
2. Check YAML frontmatter is valid
3. Ensure the filename is descriptive
4. Confirm it's in the right directory

### Maintenance

1. Mark superseded decisions as `superseded`
2. Update outdated observations
3. Archive old lessons that no longer apply
4. Keep project facts current

## File Format

All memory files use this format:

```yaml
---
type: decision|lesson|observation|project
topic: "brief topic"
status: active|superseded|deprecated|archived
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Title

Content here.
```

## Enforcement

### For Agents

- Agents MUST recall before nontrivial work
- Agents MUST save important decisions
- Agents MUST use the file format specified
- Agents MUST not save secrets or routine information
- Agents MUST update superseded memory

### For Orchestrators

- Orchestrators MUST inject memory recall into task dispatch
- Orchestrators MUST verify memory was consulted
- Orchestrators MUST request memory save after important tasks

## Rules

1. **Recall before work** — never start blind
2. **Save with reasons** — explain why something is worth remembering
3. **Quality over quantity** — fewer, better memories beat many noisy ones
4. **Maintain currency** — update or mark superseded as things change
5. **Respect the format** — consistent metadata enables search and management
6. **Never save secrets** — credentials belong in environment variables
