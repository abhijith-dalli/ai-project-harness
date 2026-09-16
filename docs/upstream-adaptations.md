# Upstream Adaptations

This document details how the AI Project Harness selectively adapts content from four upstream repositories.

## Source Repositories

| Repository | Version | License | Primary Contribution |
|---|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | v6.3.0 | MIT | Development methodology and workflow |
| [osmontero/opencode-skills](https://github.com/osmontero/opencode-skills) | v0.1.0 | MIT | OpenCode-ready agents and technical skills |
| [wshobson/agents](https://github.com/wshobson/agents) | v1.7.1 | MIT | Specialist agent ecosystem |
| [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) | v0.9.29 | Apache-2.0 | Memory concepts and optional backend |

## Adaptation Strategy

### What Was Adapted

#### From obra/superpowers (MIT)
- **Workflow methodology** — brainstorming, writing plans, executing plans, subagent-driven development, dispatching parallel agents, TDD, systematic debugging, verification before completion, requesting/receiving code review, git worktrees, finishing a development branch
- **Skill format** — SKILL.md with YAML frontmatter + Markdown body
- **Attribution preserved** — each adapted skill includes "Adapted from obra/superpowers (MIT License)"

#### From osmontero/opencode-skills (MIT)
- **Agent definitions** — implementer, spec-reviewer, code-quality-reviewer, code-reviewer, security-reviewer, internet-researcher, interface-reviewer
- **Technical skills** — reviewing-security, testing-webapps, investigating-performance, evolving-apis-and-schemas, designing-frontend-interfaces, designing-user-experience, building-accessible-interfaces, reviewing-interface-quality, writing-release-notes, building-mcp-servers
- **Skill format conventions** — "Use when..." descriptions, YAML frontmatter fields

#### From wshobson/agents (MIT)
- **Specialist agent definitions** — backend-architect, database-architect, database-optimizer, frontend-developer, ui-designer, accessibility-expert, security-auditor, threat-modeling-expert, test-automator, tdd-orchestrator, deployment-engineer, terraform-specialist
- **Plugin architecture patterns** — how agents and skills are organized
- **Model tier assignments** — which agents need which model capability levels

#### From rohitg00/agentmemory (Apache-2.0)
- **Memory concepts** — recall, remember, lesson, handoff, recap, session-history, commit-context, commit-history
- **Memory discipline methodology** — when to save, what to save, quality standards
- **Lifecycle capture patterns** — session-start, before-task, after-task, before-commit
- **MCP configuration patterns** — how to configure the agentmemory MCP server
- **Project isolation concepts** — how projects are resolved and scoped

### What Was NOT Copied

- **Provider-specific runtime internals** — no copying of plugin runtime code
- **agentmemory server/database** — not vendored into the harness
- **Entire upstream catalogs** — only selected, relevant components
- **Duplicate capabilities** — deduplicated where Superpowers and OpenCode-skills overlap
- **Evaluation-only agents** — grader, comparator, analyzer not included in runtime chain
- **Provider-specific marketplace machinery** — only adapted adapter configs

## License Preservation

### MIT License (obra/superpowers, osmontero/opencode-skills, wshobson/agents)
Each adapted file includes attribution:
```
Adapted from [repository] (MIT License)
```

### Apache-2.0 License (rohitg00/agentmemory)
Conceptual adaptations are documented here. No code was copied verbatim. The agentmemory adapter uses only the published MCP API and configuration patterns.

### Full License Texts
See `ATTRIBUTIONS.md` at the repository root for complete attribution details.

## Deduplication

Where Superpowers and OpenCode-skills provide overlapping capabilities, one canonical version was selected:

| Capability | Canonical Source | Rationale |
|---|---|---|
| brainstorming | obra/superpowers | Original methodology |
| writing-plans | obra/superpowers | Original methodology |
| systematic-debugging | obra/superpowers | Original methodology |
| test-driven-development | obra/superpowers | Original methodology |
| code review | obra/superpowers | Original workflow |
| verification | obra/superpowers | Original methodology |
| implementer agent | osmontero/opencode-skills | Concrete implementation |
| reviewer agents | osmontero/opencode-skills | Multiple reviewer types |
| security reviewing | osmontero/opencode-skills | Path-based approach |
| memory behavior | rohitg00/agentmemory | Memory-specific expertise |
