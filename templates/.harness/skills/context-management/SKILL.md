---
name: context-management
description: >
  Use when context window is limited or when working across multiple sessions.
  Manages context window efficiently by prioritizing relevant information,
  summarizing completed work, and maintaining continuity across sessions.
---

# Context Management

Manage context window efficiently across sessions and agents. Prioritize relevant information, summarize completed work, and maintain continuity.

## When to Use

- Context window is filling up
- Working across multiple sessions
- Handing off work between agents
- Summarizing long investigations
- Resuming interrupted work

## Context Prioritization

### Priority Order

1. **Current task** — what you're working on right now
2. **Relevant memory** — recalled decisions and lessons
3. **Recent changes** — what was just modified
4. **Project context** — conventions and patterns
5. **Background information** — general project knowledge

### What to Drop First

1. **Old exploration** — files read but not relevant to current task
2. **Detailed traces** — full stack traces after root cause is found
3. **Redundant information** — duplicates of what's already in context
4. **Tangential discussions** — related but not directly relevant

## Session Continuity

### Handoff Format

When ending a session or handing off:

```yaml
continuity:
  task: "current task description"
  status: "in_progress|blocked|waiting_for_review"
  completed:
    - "what was done"
  in_progress:
    - "what is currently being worked on"
  next_steps:
    - "what should happen next"
  blockers:
    - "any blockers preventing progress"
  relevant_files:
    - "files currently being modified"
  context:
    - "important context the next session needs"
```

### Resuming Work

1. Read continuity handoff from previous session
2. Read relevant memory
3. Verify current state matches expected state
4. Continue from where work stopped

## Agentmemory Context

When agentmemory is enabled, context management is partially automated:

- `SessionStart` hook recalls relevant context
- `UserPromptSubmit` hook recalls task-specific memory
- `PreToolUse` hook injects file-specific context
- Session summaries are generated at session end

## Rules

1. **Prioritize relevance** — keep what matters, drop what doesn't
2. **Summarize long content** — don't let context fill with noise
3. **Maintain continuity** — always leave clear handoff notes
4. **Verify state** — check that current state matches expectations
5. **Record important context** — save to memory before context is lost
