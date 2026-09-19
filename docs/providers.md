# Provider Adapters

The AI Project Harness supports multiple AI providers through provider adapters. Each adapter installs provider-native directories with harness skills, agents, and hooks.

## Supported Providers

| Provider | Native Directory | Skills | Agents | Hooks |
|----------|-----------------|--------|--------|-------|
| **OpenCode** | `.opencode/` | `.opencode/skills/<name>/SKILL.md` | `.opencode/agents/<name>.md` | Plugin events |
| **Claude Code** | `.claude/` | `.claude/skills/<name>/SKILL.md` | `.claude/agents/<name>.md` | `.claude/hooks.json` |
| **Cursor** | `.cursor/` | N/A (via rules) | N/A (via rules) | `.cursor/hooks.json` |
| **Codex** | `.codex/` | N/A | `.codex/agents/<name>.toml` | `.codex/hooks.json` |

## Installation

### Interactive Selection

```bash
./scripts/install.sh /path/to/project
```

This will prompt you to select a provider:

```
Select AI provider:
  1) OpenCode
  2) Claude Code
  3) Cursor
  4) Codex
Enter choice [1-4]:
```

### Provider Flag

```bash
./scripts/install.sh /path/to/project --provider opencode
./scripts/install.sh /path/to/project --provider claude
./scripts/install.sh /path/to/project --provider cursor
./scripts/install.sh /path/to/project --provider codex
```

## Provider-Specific Structures

### OpenCode

```
.opencode/
├── AGENTS.md              # Project instructions
├── skills/                # 17 harness skills
│   ├── brainstorming/SKILL.md
│   ├── planning/SKILL.md
│   └── ...
├── agents/                # 7 harness agents
│   ├── orchestrator.md
│   ├── explorer.md
│   └── ...
├── rules/
│   └── harness.md         # Points to .harness/
└── plugins/
    └── harness-hooks.js   # Lifecycle hooks via plugin events
opencode.json              # OpenCode config (root)
```

### Claude Code

```
.claude/
├── CLAUDE.md              # Project instructions
├── settings.json          # Claude Code settings
├── skills/                # 17 harness skills
│   ├── brainstorming/SKILL.md
│   ├── planning/SKILL.md
│   └── ...
├── agents/                # 7 harness agents
│   ├── orchestrator.md
│   ├── explorer.md
│   └── ...
├── hooks/                 # 6 lifecycle hooks
│   ├── session-start.sh
│   ├── prompt-submit.sh
│   ├── pre-tool-use.sh
│   ├── post-tool-use.sh
│   ├── stop.sh
│   └── session-end.sh
└── hooks.json             # Hook wiring
```

### Cursor

```
.cursor/
├── .cursorrules           # Project rules (backward compat)
├── rules/
│   └── harness.md         # Points to .harness/
├── hooks/                 # 6 lifecycle hooks
│   ├── session-start.sh
│   ├── prompt-submit.sh
│   ├── pre-tool-use.sh
│   ├── post-tool-use.sh
│   ├── stop.sh
│   └── session-end.sh
├── hooks.json             # Hook wiring
└── mcp.json               # MCP config
```

**Note:** Cursor does not support native skills/agents directories. Skills and agents are referenced from `.harness/` via rules.

### Codex

```
AGENTS.md                  # Project instructions (root)
.codex/
├── agents/                # 7 harness agents (TOML)
│   ├── orchestrator.toml
│   ├── explorer.toml
│   └── ...
├── hooks/                 # 4 lifecycle hooks
│   ├── session-start.sh
│   ├── before-task.sh
│   ├── after-task.sh
│   └── before-commit.sh
├── hooks.json             # Hook wiring
└── config.toml            # Codex configuration
```

## Exclusivity

Each provider installation is exclusive. When you install with `--provider opencode`, only the OpenCode directories are created. No `.claude/`, `.cursor/`, or `.codex/` directories will be created.

## Hook Events

### Claude Code & Cursor

| Event | Description | Harness Hook |
|-------|-------------|--------------|
| `SessionStart` | Session started | session-start |
| `UserPromptSubmit` / `beforeSubmitPrompt` | User submitted prompt | before-task |
| `PreToolUse` / `preToolUse` | Before tool execution | before-commit |
| `PostToolUse` / `postToolUse` | After tool execution | after-task |
| `Stop` / `stop` | Session stopping | session-end |
| `SessionEnd` / `sessionEnd` | Session ended | session-end |

### OpenCode

OpenCode uses plugins with event hooks:
- `session.created` → session-start
- `tool.execute.before` → before-task
- `tool.execute.after` → after-task
- `file.edited` → before-commit

### Codex

| Event | Description | Harness Hook |
|-------|-------------|--------------|
| `SessionStart` | Session started | session-start |
| `UserPromptSubmit` | User submitted prompt | before-task |
| `PreToolUse` | Before tool execution | before-commit |
| `PostToolUse` | After tool execution | after-task |
| `Stop` | Session stopping | after-task |
| `SessionEnd` | Session ended | after-task |

## Updating

To update the provider adapter:

```bash
./scripts/update.sh /path/to/project
```

This reads the provider manifest and updates the provider-specific files.

## Validation

To validate the provider installation:

```bash
./scripts/doctor.sh /path/to/project
```

This checks:
- Provider manifest exists
- Provider-specific directories exist
- Skills, agents, and hooks are installed correctly
- Provider-specific files are present
