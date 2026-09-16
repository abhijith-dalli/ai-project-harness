---
name: memory-recall
description: >
  Use before starting any nontrivial work to recall relevant project memory.
  Searches decisions, lessons, observations, and project context to inform
  current work. Auto-loads when beginning a new task.
---

# Memory Recall

Search and retrieve relevant project memory before starting work. This skill ensures you have the context needed to make informed decisions.

## When to Use

- Before starting any nontrivial task
- When you need to understand project conventions
- When investigating a bug or issue
- Before making architectural decisions
- When resuming work on a feature

## Process

1. **Identify what you need to know** — what context would help with this task?
2. **Search shared memory** — read `.harness/memory/shared/` directories
3. **Read project context** — check `.harness/project-context.md`
4. **If agentmemory is enabled** — use MCP tools for advanced search:
   - `memory_smart_search` — hybrid BM25+Vector+Graph search
   - `memory_recall` — BM25-based recall
5. **Synthesize findings** — combine relevant information
6. **Apply to current task** — use recalled memory to inform decisions

## Memory Search Strategy

### File-based memory (always available)

```
.harness/memory/shared/
├── project/          → read all files for project conventions
├── decisions/        → search for decisions related to current task
├── lessons/          → search for lessons that might apply
└── observations/     → search for relevant observations
```

### Agentmemory (when enabled)

```
memory_smart_search(query="relevant keywords", project="ProjectName")
memory_recall(query="specific topic", project="ProjectName")
```

## What to Recall

- **Project conventions** — how code is structured, naming patterns, test patterns
- **Architectural decisions** — why certain technologies were chosen
- **Known pitfalls** — debugging lessons, common mistakes
- **Related work** — previous changes to similar areas
- **Constraints** — performance, security, or compatibility requirements

## Output Format

```yaml
recalled_memory:
  task: "description of current task"
  project_context:
    - "relevant project fact 1"
    - "relevant project fact 2"
  decisions:
    - file: "path/to/decision.md"
      summary: "what was decided"
  lessons:
    - file: "path/to/lesson.md"
      summary: "what was learned"
  observations:
    - file: "path/to/observation.md"
      summary: "what was observed"
  agentmemory:
    - "relevant memory from agentmemory (if enabled)"
  application: "how this memory applies to the current task"
```

## Rules

1. **Always recall before nontrivial work** — don't start blind
2. **Be specific in searches** — use relevant keywords
3. **Synthesize, don't just list** — explain how recalled memory applies
4. **Record new findings** — after completing work, save important discoveries
5. **Respect memory states** — only use `active` memory as current truth
