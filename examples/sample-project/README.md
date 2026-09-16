# Sample Project

This is a sample project demonstrating how the AI Project Harness works in practice.

## How to Use

1. **Install the harness** (from the harness repository root):
   ```bash
   ./scripts/install.sh examples/sample-project
   ```

2. **Open with an AI agent:**
   ```bash
   cd examples/sample-project
   # Open with Claude Code, OpenCode, or Cursor
   ```

3. **Test memory:**
   - Ask: "Remember that this project uses Python and FastAPI"
   - Start a new session
   - Ask: "What technology stack does this project use?"

4. **Test isolation:**
   - Create another project
   - Install the harness there
   - Verify that memories don't cross between projects

## Project Structure After Installation

```
sample-project/
├── .harness/
│   ├── agents/          — 7 reusable agent roles
│   ├── skills/          — 17 reusable skills
│   ├── hooks/           — 4 lifecycle hooks
│   ├── memory/
│   │   ├── shared/      — durable project knowledge (committed)
│   │   └── local/       — temporary session context (gitignored)
│   ├── config/
│   │   └── harness.yaml — harness configuration
│   └── project-context.md — project-specific context
├── .claude/             — Claude Code adapter
├── .opencode/           — OpenCode adapter
├── opencode.json        — OpenCode MCP config
└── README.md            — this file
```

## What to Try

### As an Orchestrator
Ask the AI to "implement a simple REST endpoint" and watch it:
1. Classify the task complexity
2. Recall relevant memory
3. Select the appropriate agent chain
4. Execute through explorer → implementer → reviewer

### As an Implementer
Ask the AI to "add a new feature" and watch it:
1. Recall project conventions
2. Follow TDD (write test first)
3. Implement with self-review
4. Save important findings to memory

### As a Debugger
Ask the AI to "fix this bug" and watch it:
1. Reproduce the failure
2. Investigate root cause
3. Make minimal fix
4. Save lesson to memory

## Sample Memory

The `memory/shared/` directory can contain:

```
shared/
├── project/
│   └── stack.md          — "This project uses Python 3.12, FastAPI, PostgreSQL"
├── decisions/
│   └── 001-api-design.md — "REST API with OpenAPI spec"
├── lessons/
│   └── 001-cors.md       — "CORS must be configured for local dev"
└── observations/
    └── 001-perf.md       — "Response time < 50ms for list endpoints"
```

## Configuration

Edit `.harness/config/harness.yaml` to:
- Enable/disable providers
- Enable agentmemory integration
- Enable specialist packs
- Configure memory behavior
