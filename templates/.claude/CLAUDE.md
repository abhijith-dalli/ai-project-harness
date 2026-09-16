# Claude Code Project Instructions

> This file is loaded by Claude Code when working in this project.
> It provides project-specific context and instructions.

## Project Context

Read `.harness/project-context.md` for project-specific information.

## Memory

This project uses the `.harness/memory/` architecture for persistent knowledge:
- `shared/` — durable project knowledge (committed)
- `local/` — temporary session context (gitignored)

If agentmemory is enabled, it provides an optional advanced backend for memory operations. The canonical memory source remains `.harness/memory/shared/`.

## Skills

Available skills are in `.harness/skills/`. They are loaded on demand by the skill tool when triggered by conversation context.

## Agents

Available agent roles are in `.harness/agents/`. They can be dispatched as subagents for specialized work.

## Workflow

1. Before starting work, recall relevant memory from `.harness/memory/shared/`
2. Follow project conventions from `.harness/project-context.md`
3. After completing work, save important findings to project memory
4. Use the harness lifecycle: explore → plan → implement → review → verify
