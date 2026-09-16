# AI Project Harness

**A reusable, provider-independent AI project harness with isolated project memory.**

One harness installed into many projects. Each project gets reusable skills, agents, hooks, configuration, and isolated memory — while Claude Code, Cursor, and OpenCode remain globally installed.

```
Developer Machine
│
├── Claude Code          (global application)
├── Cursor               (global application)
├── OpenCode             (global application)
│
└── MyProject
    │
    ├── .harness/                     ← SOURCE OF TRUTH
    │   ├── agents/
    │   ├── skills/
    │   ├── hooks/
    │   ├── memory/
    │   │   ├── shared/               ← committed
    │   │   └── local/                ← gitignored
    │   ├── config/
    │   └── project-context.md
    │
    ├── .claude/                     ← Claude Code adapter
    ├── .opencode/                   ← OpenCode adapter
    ├── .cursor/                     ← Cursor adapter
    └── application source
```

## Key Principles

- **`.harness/` is the single source of truth** — provider-specific directories are adapters/generated views only
- **Project-scoped memory** — memory for Project A never leaks into Project B
- **File-based memory** — works without any server; memory is stored as markdown files
- **Real upstream content** — agents and skills adapt real implementations from proven repositories
- **Idempotent installer** — run it twice without corruption

---

## Quick Start

### Prerequisites

- **Git**
- One or more AI agents: Claude Code, Cursor, or OpenCode (globally installed)

### Step 1 — Clone the harness

```bash
git clone https://github.com/abhijith-dalli/ai-project-harness.git
cd ai-project-harness
```

### Step 2 — Install into your project

```bash
./scripts/install.sh /path/to/YourProject
```

### Step 3 — Verify installation

```bash
./scripts/doctor.sh /path/to/YourProject
```

### Step 4 — Open your project

```bash
cd /path/to/YourProject
```

Then use Claude Code, Cursor, or OpenCode as normal. The harness is automatically available.

---

## Installation

### What the installer does

1. Validates the target project directory
2. Detects Git repository status
3. Creates `.harness/` directory with all components
4. Installs skills, agents, hooks, and configuration
5. Creates project identity and memory scope
6. Configures supported agent integrations (Claude Code, OpenCode, Cursor)
7. Preserves existing files (idempotent)
8. Adds safe `.gitignore` rules

### Install into an existing project

```bash
./scripts/install.sh /path/to/YourProject
```

With options:

```bash
# Enable Cursor adapter
./scripts/install.sh /path/to/YourProject --enable-cursor

# Enable specialist packs
./scripts/install.sh /path/to/YourProject --packs backend,database,testing

# Combine options
./scripts/install.sh /path/to/YourProject --enable-cursor --packs backend,database
```

The installer creates:

```
YourProject/
├── .harness/
│   ├── agents/           # 7 reusable agent roles
│   ├── skills/           # 17 reusable skills
│   ├── hooks/            # 4 lifecycle hooks
│   ├── memory/
│   │   ├── shared/       # Durable project knowledge (committed)
│   │   └── local/        # Temporary session context (gitignored)
│   ├── config/
│   │   └── harness.yaml  # Harness configuration
│   └── project-context.md
├── .claude/              # Claude Code adapter
├── .opencode/            # OpenCode adapter
├── opencode.json         # OpenCode config
└── [your existing source code]
```

### What does NOT get created

- The harness repository is NOT copied into your project
- Claude Code, Cursor, or OpenCode applications are NOT installed

### Idempotent installation

Running the installer again will:

- Update harness-managed files to the latest version
- Preserve project-specific memory, context, and customizations
- Not overwrite existing `.harness/project-context.md`
- Not delete `.harness/memory/` contents

---

## Architecture

### Source of truth

```
.harness/                     ← canonical provider-independent source
    ↓
.claude/   .opencode/   .cursor/
    ↓
provider-specific adapters/generated views only
```

`.harness/` owns the canonical agents, skills, workflows, hooks, memory model, and project context. Provider-specific files are adapters generated from `.harness/`.

### Memory model

```
.harness/memory/
├── shared/                   ← durable project knowledge; commit when appropriate
│   ├── project/              # stable project facts and conventions
│   ├── decisions/            # architectural and technical decisions
│   ├── lessons/              # mistakes, debugging lessons, reusable findings
│   └── observations/         # useful discoveries
└── local/                    ← temporary/private session context; normally gitignored
    └── sessions/
```

**Shared memory** is durable project knowledge that should be committed to version control. It survives across sessions and agents.

**Local memory** is temporary session context. It is normally gitignored and not shared.

### Workflow

```
USER TASK
   ↓
ORCHESTRATOR
   ↓
Memory Recall
   ↓
Task Classification
   │
   ├── TRIVIAL → IMPLEMENTER
   ├── SMALL → EXPLORER → IMPLEMENTER → REVIEWER
   ├── MEDIUM → EXPLORER → PLANNER → IMPLEMENTER → REVIEWER
   └── LARGE → EXPLORER → PLANNER → IMPLEMENTER → REVIEWER → DEBUGGER (if needed)
                                                   │
                              PASS → VERIFY → MEMORY UPDATE → DONE
                              FAIL → DEBUGGER
                                         ├→ IMPLEMENTER → REVIEWER
                                         └→ PLANNER → IMPLEMENTER → REVIEWER
```

---

## Components

### Agents (7 core roles)

| Agent | Purpose |
|-------|---------|
| **orchestrator** | Classifies task complexity, recalls relevant memory, selects the smallest useful agent chain, coordinates handoffs |
| **explorer** | Read-only codebase exploration — traces behavior, identifies files, reports facts without implementing |
| **researcher** | External technical research — resolves uncertainty with authoritative sources, records versions and limitations |
| **planner** | Creates implementation plans from findings — identifies files, dependencies, risks, tests, acceptance criteria |
| **implementer** | Executes approved plans with TDD, self-review, and structured status reporting |
| **reviewer** | Multi-dimension code review — requirement compliance, correctness, maintainability, security, tests |
| **debugger** | Systematic root cause investigation — reproduce, establish expected vs actual, isolate defect, minimal fix |

### Skills (17 core skills)

| Skill | Purpose |
|-------|---------|
| **memory-recall** | Search and retrieve relevant project memory before starting work |
| **memory-save** | Persist important decisions, lessons, and observations to project memory |
| **memory-discipline** | Codifies when to recall, what to save, and memory quality standards |
| **context-management** | Manage context window efficiently across sessions and agents |
| **codebase-exploration** | Structured approach to understanding existing code before making changes |
| **brainstorming** | Creative exploration and design before implementation — three paths: spike, bounded, architectural |
| **planning** | Detailed implementation plans with bite-sized tasks, exact file paths, verification steps |
| **executing-plans** | Batch execution with review checkpoints — load plan, execute tasks, report complete |
| **systematic-debugging** | 4-phase root cause process: investigate, pattern analysis, hypothesis testing, implementation |
| **test-driven-development** | RED-GREEN-REFACTOR cycle — no production code without a failing test first |
| **testing** | Test strategy, organization, and quality standards |
| **requesting-code-review** | Pre-merge review dispatch — crafted context, severity-graded issues |
| **receiving-code-review** | Technical evaluation of feedback — verify before implementing, push back if wrong |
| **verifying-before-completion** | Evidence before claims — must run verification commands and confirm output |
| **dispatching-parallel-agents** | Concurrent work across independent problem domains |
| **subagent-driven-development** | Fresh subagent per task with two-stage review (spec + quality) |
| **git-workflow** | Git worktrees for isolation and branch finishing workflow |

### Hooks (4 lifecycle events)

| Hook | When | What it does |
|------|------|-------------|
| **session-start** | AI agent session begins | Recall relevant project context, inject memory into prompt |
| **before-task** | Before starting work on a task | Recall task-specific memory, check project conventions |
| **after-task** | After completing a task | Save important decisions, lessons, and observations |
| **before-commit** | Before git commit | Capture commit context, record what changed and why |

### Provider adapters

| Provider | Files | Integration |
|----------|-------|-------------|
| **Claude Code** | `.claude/settings.json`, `.claude/hooks.json`, `.claude/CLAUDE.md` | Hook wiring, project instructions |
| **OpenCode** | `opencode.json`, `.opencode/AGENTS.md` | Project instructions |
| **Cursor** | `.cursor/mcp.json`, `.cursor/hooks.json`, `.cursor/.cursorrules` | Hook wiring, project rules |

### Specialist packs

Optional domain-specific agents can be enabled per project:

| Pack | Agents included |
|------|----------------|
| **backend** | backend-architect |
| **database** | database-architect, database-optimizer |
| **frontend** | frontend-developer, ui-designer, accessibility-expert |
| **security** | security-auditor, threat-modeling-expert |
| **testing** | test-automator, tdd-orchestrator |
| **devops** | deployment-engineer, terraform-specialist |

---

## Memory System

### Project-scoped isolation

Each project has its own isolated memory scope. Memory created for Project A never appears when working on Project B.

```
TaxSystem/.harness/memory/
RecruitmentSystem/.harness/memory/
OESSystem/.harness/memory/
```

### Cross-agent sharing

All supported AI agents on the same project share the same memory:

```
     ┌── Claude Code
     │
     ├── OpenCode
     │
     └── Cursor
           │
           ▼
  .harness/memory/shared/
```

When OpenCode learns "TaxSystem uses Flask and PostgreSQL," Claude Code can recall that information when working on the same project.

### Memory file format

Memory files use markdown with YAML frontmatter:

```yaml
---
type: lesson
topic: compliance-workflow
status: active
created: 2026-09-16
updated: 2026-09-16
---

# Lesson

When implementing compliance checks, always validate input against the schema
before processing.
```

**Supported states:** `active`, `superseded`, `deprecated`, `archived`

### What to persist

- Stable project facts and conventions
- Architecture and technical decisions
- Important implementation constraints
- Debugging lessons and reusable findings
- Meaningful observations about the codebase

### What NOT to persist

- Passwords, API keys, tokens, or secrets
- Raw conversation dumps
- Routine tool output
- Temporary debugging noise
- Duplicate knowledge

---

## Configuration

### harness.yaml

```yaml
harness:
  version: "1.0.0"
  project_name: ""

providers:
  claude_code:
    enabled: true
    hooks: true
  opencode:
    enabled: true
    hooks: true
  cursor:
    enabled: false
    hooks: true

specialist_packs: []

memory:
  shared_path: ".harness/memory/shared"
  local_path: ".harness/memory/local"

hooks:
  session_start: true
  before_task: true
  after_task: true
  before_commit: true
```

---

## Scripts Reference

### install.sh

```bash
./scripts/install.sh /path/to/project [--enable-cursor] [--enable-codex] [--packs backend,database]
```

Installs the harness into a target project. Idempotent — safe to run multiple times.

### update.sh

```bash
./scripts/update.sh /path/to/project
```

Updates harness-managed files while preserving project memory, context, and customizations.

### doctor.sh

```bash
./scripts/doctor.sh /path/to/project
```

Verifies: Git, project identity, memory scope, provider integrations, hooks, skills.

### status.sh

```bash
./scripts/status.sh /path/to/project
```

Shows: harness version, components, memory status, provider status.

### bootstrap.sh

```bash
./scripts/bootstrap.sh /path/to/project [--packs backend,database]
```

Quick setup: installs harness, runs doctor, verifies memory, prints next steps.

---

## How to Install Into a Local Project

### Step 1 — Clone the harness

```bash
git clone https://github.com/abhijith-dalli/ai-project-harness.git
cd ai-project-harness
```

### Step 2 — Install into your project

```bash
./scripts/install.sh /path/to/YourProject
```

### Step 3 — Configure project context

Edit `.harness/project-context.md` in your project:

```markdown
# Project Context

## Project
**Name:** MyProject
**Purpose:** What this project does

## Technology
**Language:** Python 3.12
**Framework:** FastAPI
```

### Step 4 — Verify

```bash
./scripts/doctor.sh /path/to/YourProject
```

### Step 5 — Use it

Open the project with Claude Code, Cursor, or OpenCode. The harness is automatically available.

---

## How to Update

```bash
cd ai-project-harness
git pull
./scripts/update.sh /path/to/YourProject
./scripts/doctor.sh /path/to/YourProject
```

The updater preserves project memory, context, and customizations.

---

## Day-to-Day Workflow

```
Open project → Start AI agent → Harness loads context → Work → Memory saved
```

1. Open your project
2. Start Claude Code, Cursor, or OpenCode
3. The orchestrator classifies your task and selects agents
4. Memory is recalled before work, saved after work
5. Important knowledge persists across sessions

---

## Security

### Never commit

- API keys, access tokens, passwords
- Private keys, database credentials
- `.env` secrets

### Credential management

Supply credentials through environment variables or `.env` files (gitignored).

See `.env.example` for available options.

---

## Testing

```bash
cd ai-project-harness
for test in tests/*.sh; do bash "$test"; done
```

| Test | What it verifies |
|------|-----------------|
| **install-test.sh** | Expected files exist after installation |
| **memory-isolation-test.sh** | ProjectA memory does not leak into ProjectB |
| **cross-agent-memory-test.sh** | Memory is provider-independent |
| **canonical-memory-test.sh** | File-based memory works without any server |
| **reinstall-test.sh** | Second installation does not corrupt project |

---

## Upstream Adaptations

| Repository | Contribution |
|-----------|-------------|
| **obra/superpowers** | Development methodology — brainstorming, planning, TDD, debugging, code review, SDD |
| **osmontero/opencode-skills** | Concrete agents and technical skills — implementer, reviewers, security, testing |
| **wshobson/agents** | Specialist ecosystem — backend, database, frontend, security, testing, devops packs |
| **rohitg00/agentmemory** | Memory concepts — recall, save, lesson, handoff (conceptual adaptation only) |

See `docs/upstream-adaptations.md` for detailed attribution.

---

## Quick Reference

```bash
# Install
./scripts/install.sh /path/to/project

# Verify
./scripts/doctor.sh /path/to/project

# Status
./scripts/status.sh /path/to/project

# Update
cd ai-project-harness && git pull
./scripts/update.sh /path/to/project

# Tests
for test in tests/*.sh; do bash "$test"; done
```

---

## License

This project is provided as-is. See `ATTRIBUTIONS.md` for upstream license preservation.
