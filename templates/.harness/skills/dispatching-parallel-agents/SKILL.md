---
name: dispatching-parallel-agents
description: >
  Use when multiple independent investigations or tasks can be performed
  concurrently. Dispatches subagents for parallel work on independent
  pieces, then synthesizes results.
---

# Dispatching Parallel Agents

Execute independent tasks concurrently by dispatching subagents. Only parallelize work that is truly independent — never parallelize conflicting mutations.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Multiple independent files need investigation
- Research tasks can run concurrently
- Code review of independent changes
- Exploration of multiple approaches
- Testing independent components

## When NOT to Parallelize

- Tasks that modify the same files
- Tasks with dependencies between them
- Tasks that require shared state
- Tasks that produce conflicting mutations
- When the runtime doesn't support true parallelism

## Parallel Dispatch Format

```yaml
parallel_tasks:
  - id: "task-1"
    agent: "explorer"
    prompt: "Investigate the authentication module"
    inputs:
      - "src/auth/"
    expected_output: "Report on auth architecture"

  - id: "task-2"
    agent: "explorer"
    prompt: "Investigate the database layer"
    inputs:
      - "src/db/"
    expected_output: "Report on DB architecture"
```

## Process

### Step 1: Identify Independent Tasks
- Can these tasks run without shared state?
- Do they modify different files?
- Can their results be combined safely?

### Step 2: Dispatch Subagents
- Create clear, specific prompts for each agent
- Include all necessary context in each prompt
- Specify expected output format

### Step 3: Collect Results
- Wait for all agents to complete
- Review each agent's output
- Check for contradictions or conflicts

### Step 4: Synthesize
- Combine results into a coherent picture
- Resolve any contradictions
- Present unified findings

## Safety Rules

1. **Independent mutations only** — never parallelize writes to the same file
2. **Read-only exploration is always safe** — parallelize freely
3. **Merge conflicts are your fault** — if parallel agents modify the same file
4. **Sequential for dependent tasks** — if B depends on A, run A first
5. **One agent per file modification** — when in doubt, serialize

## Rules

1. **Only parallelize truly independent work** — when in doubt, serialize
2. **Clear prompts** — each agent needs complete context
3. **Synthesize results** — don't just collect, combine
4. **Check for conflicts** — parallel agents may disagree
5. **Document what was parallelized** — for future reference
