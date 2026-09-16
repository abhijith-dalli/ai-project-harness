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
    │   ├── adapters/
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
- **Optional agentmemory** — the harness works without agentmemory; agentmemory augments when enabled
- **Real upstream content** — agents and skills adapt real implementations from proven repositories
- **Idempotent installer** — run it twice without corruption

---

## Quick Start

### Prerequisites

- **Git**
- **Node.js 20+** and **npm/npx** (required for optional agentmemory integration)
- One or more AI agents: Claude Code, Cursor, or OpenCode (globally installed)

### Step 1 — Clone the harness

```bash
git clone https://github.com/<your-org>/ai-project-harness.git
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
3. Detects Node.js/npm availability
4. Optionally detects and configures agentmemory (when enabled)
5. Creates `.harness/` directory with all components
6. Installs skills, agents, hooks, and configuration
7. Creates project identity and memory scope
8. Configures supported agent integrations (Claude Code, OpenCode, Cursor)
9. Preserves existing files (idempotent)
10. Adds safe `.gitignore` rules
11. Runs verification

### Install into an existing project

```bash
./scripts/install.sh /path/to/YourProject
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
│   ├── adapters/         # Provider integration guides
│   ├── config/
│   │   └── harness.yaml  # Harness configuration
│   └── project-context.md
├── .claude/              # Claude Code adapter (if supported)
├── .cursor/              # Cursor adapter (if supported)
└── opencode.json         # OpenCode adapter (if supported)
```

### What does NOT get created

- The harness repository is NOT copied into your project
- A separate agentmemory server is NOT installed per project
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

### Optional agentmemory integration

When agentmemory is enabled:

- The harness uses the real `@agentmemory/mcp` MCP server
- Project scoping follows agentmemory's `resolveProject()` mechanism (git basename or `AGENTMEMORY_PROJECT_NAME` env)
- Skills like recall, remember, lesson, handoff, recap, commit-context, commit-history, and session-history are available through MCP
- The harness's `.harness/memory/shared/` remains the canonical durable memory source
- agentmemory augments with advanced search, graph extraction, and consolidation

When agentmemory is disabled:

- The harness operates entirely on file-based memory in `.harness/memory/`
- All skills and agents still function
- Memory is stored as markdown files with YAML frontmatter

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
| **testing** | Web application testing with Playwright and verification strategies |
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
| **Claude Code** | `.claude/settings.json`, `CLAUDE.md` | MCP server config, hook wiring, plugin reference |
| **OpenCode** | `opencode.json` | MCP server config, plugin reference |
| **Cursor** | `.cursor/mcp.json` | MCP server configuration |

---

## Memory System

### Project-scoped isolation

Each project has its own isolated memory scope. Memory created for Project A never appears when working on Project B.

```
agentmemory
├── TaxSystem memory
│   ├── decisions/
│   ├── lessons/
│   ├── observations/
│   └── project context
│
├── RecruitmentSystem memory
│   ├── decisions/
│   ├── lessons/
│   └── observations/
│
└── OESSystem memory
    ├── decisions/
    ├── lessons/
    └── observations/
```

### Cross-agent sharing

All supported AI agents on the same project share the same memory:

```
     ┌── Claude Code
     │
agentmemory ←── Project memory
     │
     └── OpenCode
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

## Lesson

When implementing compliance checks, always validate input against the schema
before processing. The validation layer must reject malformed input at the
boundary, not downstream.
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
# Project identity
project:
  name: "MyProject"
  description: "Description of the project"

# Memory settings
memory:
  provider: "file"                    # "file" or "agentmemory"
  agentmemory:
    enabled: false                    # set to true to enable agentmemory
    project_name: null                # override project name (default: git basename)

# Specialist packs (optional)
specialist_packs: []
  # - backend
  # - database
  # - frontend
  # - security
  # - testing
  # - devops

# Hook behavior
hooks:
  session_start:
    recall_memory: true
    inject_context: true
  before_task:
    recall_memory: true
  after_task:
    save_decisions: true
    save_lessons: true
  before_commit:
    capture_context: true
```

### Specialist packs

Optional domain-specific agents can be enabled per project:

| Pack | Agents included |
|------|----------------|
| **backend** | backend-architect, api-designer |
| **database** | database-architect, database-optimizer |
| **frontend** | frontend-developer, ui-designer, accessibility-expert |
| **security** | security-auditor, threat-modeling-expert |
| **testing** | test-automator, tdd-orchestrator |
| **devops** | deployment-engineer, terraform-specialist |

Only enable packs relevant to your project's technology stack.

---

## Scripts Reference

### install.sh

```bash
./scripts/install.sh /path/to/project
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

Verifies: Git, Node.js, agentmemory (if enabled), project identity, memory scope, MCP configuration, provider integrations, hooks, skills, permissions.

### status.sh

```bash
./scripts/status.sh /path/to/project
```

Shows: harness version, agentmemory version (if enabled), memory status, integration status.

### start.sh / stop.sh

```bash
./scripts/start.sh /path/to/project
./scripts/stop.sh /path/to/project
```

Manages the optional agentmemory service. Only required when agentmemory is enabled.

### bootstrap.sh

```bash
./scripts/bootstrap.sh /path/to/project
```

Quick setup: installs harness, runs doctor, verifies memory, prints next steps.

---

## Updating the Harness

### Check current version

```bash
./scripts/status.sh /path/to/YourProject
```

### Get latest harness

```bash
cd ai-project-harness
git pull
```

### Run the updater

```bash
./scripts/update.sh /path/to/YourProject
```

### Verify after update

```bash
./scripts/doctor.sh /path/to/YourProject
```

The updater preserves:

- `.harness/project-context.md`
- `.harness/memory/` contents
- Project-specific configuration
- Application source code

---

## Security

### Never commit

- API keys, access tokens, passwords
- Private keys, database credentials
- MCP secrets, `.env` secrets
- Machine-specific credentials

### The installer creates

- `.gitignore` rules for sensitive files
- `.env.example` with placeholder values

### Credential management

Supply credentials through environment variables:

```bash
export AGENTMEMORY_SECRET="your-secret-here"
export OPENAI_API_KEY="your-key-here"
```

Or through `.env` files (gitignored).

---

## Testing

### Run all tests

```bash
cd tests
./install-test.sh
./memory-isolation-test.sh
./cross-agent-memory-test.sh
./reinstall-test.sh
./update-test.sh
```

### What is tested

| Test | What it verifies |
|------|-----------------|
| **install-test.sh** | Expected files exist after installation |
| **memory-isolation-test.sh** | ProjectA memory does not leak into ProjectB |
| **cross-agent-memory-test.sh** | Memory stored via one agent is recalled by another |
| **reinstall-test.sh** | Second installation does not corrupt project |
| **update-test.sh** | Version update preserves project-specific data |

---

## Agent Integration Guides

### Claude Code

The harness creates `.claude/settings.json` with MCP server configuration and hooks.

**Setup:**
1. Install harness into project
2. Open project with Claude Code
3. The MCP server and hooks are automatically configured

**How it works:**
- MCP server (`@agentmemory/mcp`) provides 54 tools for memory operations
- Hooks inject recalled memory at session start and before tasks
- Skills are available through the MCP integration

### OpenCode

The harness creates `opencode.json` with MCP server configuration.

**Setup:**
1. Install harness into project
2. Open project with OpenCode
3. The MCP server is automatically available

**How it works:**
- MCP server configured at top level in `opencode.json`
- Slash commands `/recall` and `/remember` available when agentmemory is enabled
- 22 auto-capture hooks available when agentmemory plugin is enabled

### Cursor

The harness creates `.cursor/mcp.json` with MCP server configuration.

**Setup:**
1. Install harness into project
2. Open project with Cursor
3. The MCP server is available through Cursor's MCP integration

**How it works:**
- MCP server provides memory tools
- 7 hooks available when agentmemory plugin is installed
- Skills accessible through MCP tools

---

## Troubleshooting

### Installation fails

- Ensure Node.js 20+ is installed: `node --version`
- Ensure npm is installed: `npm --version`
- Ensure Git is installed: `git --version`
- Ensure the target directory exists and is writable

### Doctor reports issues

Run `./scripts/doctor.sh /path/to/project` and follow the specific recommendations for each failed check.

### Memory not persisting

- Verify `.harness/memory/shared/` directory exists
- Check file permissions
- If using agentmemory, verify the service is running: `./scripts/status.sh /path/to/project`

### Agent cannot find skills

- Verify `.harness/skills/` directory contains the expected skill directories
- Check that provider adapter files are correctly configured
- Run doctor to verify integration status

---

## Upstream Adaptations

This harness adapts real implementations from four upstream repositories:

| Repository | Contribution |
|-----------|-------------|
| **obra/superpowers** | Development methodology — brainstorming, planning, TDD, debugging, code review, SDD, git worktrees |
| **osmontero/opencode-skills** | Concrete agents and technical skills — implementer, reviewers, security, research, testing |
| **wshobson/agents** | Specialist ecosystem — optional backend, database, frontend, security, testing, devops packs |
| **rohitg00/agentmemory** | Memory concepts and optional backend — recall, save, lesson, handoff, recap, hooks, MCP |

See `docs/upstream-adaptations.md` for detailed attribution and license preservation.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the existing patterns
4. Run tests
5. Submit a pull request

### Adding a new skill

1. Create `templates/.harness/skills/your-skill/SKILL.md`
2. Follow the YAML frontmatter format: `name` and `description` fields
3. Include trigger phrases in the description: "Use when...", "Auto-loads when..."
4. Add to `docs/skills.md`

### Adding a new agent

1. Create `templates/.harness/agents/your-agent.md`
2. Follow the YAML frontmatter format: `name`, `description`, `mode`
3. Include behavioral instructions in the body
4. Add to `docs/agents.md`

---

## License

This project is provided as-is. See `ATTRIBUTIONS.md` for upstream license preservation.
