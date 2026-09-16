# OpenCode Project Instructions

> This file is loaded by OpenCode when working in this project.

## Project Context

Read `.harness/project-context.md` for project-specific information.

## Memory

This project uses the `.harness/memory/` architecture for persistent knowledge:
- `shared/` — durable project knowledge (committed)
- `local/` — temporary session context (gitignored)

## Skills

Available skills are in `.harness/skills/`. They are loaded on demand by the skill tool.

## Agents

Available agent roles are in `.harness/agents/`. They can be dispatched as subagents.

## Commands

- `/recall` — Search and retrieve relevant project memory
- `/remember` — Save important findings to project memory

## Workflow

1. Before starting work, recall relevant memory
2. Follow project conventions from `.harness/project-context.md`
3. After completing work, save important findings to project memory
