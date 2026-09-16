# Skills

Complete catalog of harness skills, their sources, and usage.

## Core Skills (17)

### Workflow Skills

| Skill | Source | Description |
|---|---|---|
| brainstorming | obra/superpowers | Three-path design refinement before coding |
| planning | obra/superpowers | Detailed implementation plans with bite-sized tasks |
| executing-plans | obra/superpowers | Batch execution with review checkpoints |
| subagent-driven-development | obra/superpowers | Fresh subagent per task, two-stage review |
| dispatching-parallel-agents | obra/superpowers | Concurrent subagent workflows |
| requesting-code-review | obra/superpowers | Pre-review checklist and dispatch |
| receiving-code-review | obra/superpowers | Technical evaluation of review feedback |
| verification-before-completion | obra/superpowers | Evidence before claims, no "should work" |
| systematic-debugging | obra/superpowers | 4-phase root cause investigation |
| test-driven-development | obra/superpowers | RED-GREEN-REFACTOR cycle |
| testing | original | Test strategy, organization, and quality |
| git-workflow | obra/superpowers | Branch management, worktrees, finishing |

### Memory Skills

| Skill | Source | Description |
|---|---|---|
| memory-recall | original | Search and retrieve project memory before work |
| memory-save | original | Persist decisions, lessons, observations |
| memory-discipline | original | Quality standards for what to save |

### Exploration Skills

| Skill | Source | Description |
|---|---|---|
| codebase-exploration | original | 4-phase codebase exploration |
| context-management | original | Context window efficiency |

## Skills from Specialist Packs

When specialist packs are enabled, additional skills become available:

### Backend Pack
- API design patterns
- Microservices architecture
- RESTful API conventions

### Database Pack
- SQL optimization patterns
- Migration strategies
- Schema design

### Frontend Pack
- React component patterns
- Responsive design
- State management

### Security Pack
- OWASP compliance patterns
- Threat modeling methodology
- Security review checklists

### Testing Pack
- Test pyramid strategy
- Mocking patterns
- E2E testing with Playwright

### DevOps Pack
- CI/CD pipeline patterns
- Containerization best practices
- Infrastructure as Code

## Skill Format

Each skill follows this structure:

```
skills/<skill-name>/
├── SKILL.md           # Required: YAML frontmatter + Markdown instructions
├── references/        # Optional: supporting documentation
└── scripts/           # Optional: helper scripts
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name
description: >
  Use when [triggering conditions].
  [Brief description of what the skill does].
---
```

### Description Convention

Descriptions start with "Use when..." and describe triggering conditions only, not the workflow.

## Skill Loading

Skills are loaded on demand by the skill tool when triggered by conversation context. They are not loaded all at once — only the relevant skill is activated for the current task.

## Skill Interaction with Memory

Skills interact with project memory through:
- `memory-recall` — before starting work
- `memory-save` — after completing work
- `memory-discipline` — quality standards throughout

## Agent-Skill Compatibility

| Skill | Compatible Agents |
|---|---|
| brainstorming | orchestrator, planner |
| planning | planner, orchestrator |
| executing-plans | implementer, orchestrator |
| systematic-debugging | debugger, implementer |
| test-driven-development | implementer, tester |
| code review | reviewer |
| verification | implementer, reviewer |
| memory-recall | all agents |
| memory-save | all agents |
