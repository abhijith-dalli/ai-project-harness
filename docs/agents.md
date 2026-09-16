# Agents

Complete catalog of harness agent roles, their responsibilities, and usage.

## Core Agents (7)

### Orchestrator

**File:** `agents/orchestrator.md`
**Mode:** orchestrator
**Purpose:** Classifies task complexity and coordinates the appropriate agent chain.

**Responsibilities:**
- Classify task complexity (TRIVIAL/SMALL/MEDIUM/LARGE)
- Recall relevant memory
- Select the smallest useful agent chain
- Coordinate structured handoffs
- Avoid unnecessary multi-agent execution

**When to Use:**
- For any non-trivial task
- When unsure which agents to involve
- For complex multi-step work

**Agent Chain Patterns:**
- TRIVIAL → implementer only
- SMALL → explorer → implementer → reviewer
- MEDIUM → explorer → planner → implementer → reviewer
- LARGE → explorer → planner → implementer → reviewer → debugger

---

### Explorer

**File:** `agents/explorer.md`
**Mode:** subagent
**Permission:** edit: deny
**Purpose:** Read-only codebase exploration and fact-finding.

**Responsibilities:**
- Trace existing behavior
- Identify relevant files
- Report facts with evidence (file:line references)
- Never modify files

**When to Use:**
- Before implementing changes
- When investigating bugs
- When understanding existing code
- For codebase orientation

---

### Researcher

**File:** `agents/researcher.md`
**Mode:** subagent
**Permission:** edit: deny
**Purpose:** External technical research and fact-checking.

**Responsibilities:**
- Resolve external technical uncertainty
- Prefer authoritative/current sources
- Record versions and limitations
- Distinguish facts from assumptions

**Research Modes:**
- Quick fact-check (seconds)
- Standard research (minutes)
- Deep dive (extended investigation)

---

### Planner

**File:** `agents/planner.md`
**Mode:** subagent
**Purpose:** Create detailed implementation plans from findings.

**Responsibilities:**
- Create plans with bite-sized tasks (2-5 minutes each)
- Identify exact file paths, dependencies, risks
- Include verification steps and acceptance criteria
- Avoid premature coding

**When to Use:**
- After exploration reveals complexity
- For medium or large tasks
- When multiple files need changes

---

### Implementer

**File:** `agents/implementer.md`
**Mode:** subagent
**Purpose:** Execute approved plans with TDD and self-review.

**Responsibilities:**
- Follow project instructions and memory
- Implement with TDD (RED-GREEN-REFACTOR)
- Self-review before handoff
- Report affected files and verification

**Status Values:**
- DONE — task complete, all tests pass
- DONE_WITH_CONCERNS — complete but with noted concerns
- BLOCKED — cannot proceed, needs help
- NEEDS_CONTEXT — missing information

---

### Reviewer

**File:** `agents/reviewer.md`
**Mode:** subagent
**Permission:** edit: deny
**Purpose:** Multi-dimension code review.

**Review Dimensions:**
1. Spec compliance — does it match the requirements?
2. Correctness — does the code work?
3. Maintainability — is it easy to understand?
4. Security — are there vulnerabilities?
5. Tests — are tests adequate?

**Severity Levels:**
- Critical — blocks merge
- Important — must fix before merge
- Minor — can be deferred

---

### Debugger

**File:** `agents/debugger.md`
**Mode:** subagent
**Purpose:** Systematic root cause investigation.

**Responsibilities:**
- Reproduce failure
- Establish expected vs actual
- Isolate defect
- Make smallest justified fix
- Rerun targeted and regression tests

**Iron Law:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

**After 3+ Failed Fixes:** Question the architecture itself.

---

## Specialist Agents (from Packs)

When specialist packs are enabled, additional agents become available:

### Backend Pack
- **backend-architect** — RESTful API design, microservice boundaries, database schemas

### Database Pack
- **database-architect** — Database design, technology selection, schema modeling
- **database-optimizer** — Query optimization, index design, migration strategies

### Frontend Pack
- **frontend-developer** — React components, responsive layouts, client-side state
- **ui-designer** — UI/UX design, wireframes, design systems
- **accessibility-expert** — WCAG compliance, accessibility audits

### Security Pack
- **security-auditor** — Vulnerability assessment, OWASP compliance
- **threat-modeling-expert** — STRIDE threat modeling, attack trees

### Testing Pack
- **test-automator** — Comprehensive test suite creation
- **tdd-orchestrator** — TDD methodology guidance

### DevOps Pack
- **deployment-engineer** — CI/CD pipelines, containerization
- **terraform-specialist** — Infrastructure as Code

## Agent Interaction Model

Agents exchange compact handoffs, not full transcripts:

```yaml
handoff:
  task: "..."
  status: "complete"
  findings:
    - "..."
  evidence:
    - "..."
  decisions:
    - "..."
  affected_files:
    - "..."
  tests:
    - "..."
  recommended_next_step: "..."
```

Each agent receives only:
- The original requirement
- Project instructions
- Relevant memory
- Previous handoff
- Relevant file paths

## Agent Memory Behavior

All agents:
1. **Before work:** Recall relevant memory from `.harness/memory/shared/`
2. **During work:** Follow project conventions and memory
3. **After work:** Save important findings to project memory

## Agent File Format

Each agent is a Markdown file with YAML frontmatter:

```yaml
---
name: agent-name
description: >
  Triggering description for when to use this agent.
mode: subagent | orchestrator
permission:
  edit: deny | allow
model: opus | sonnet | haiku | inherit
---
```
