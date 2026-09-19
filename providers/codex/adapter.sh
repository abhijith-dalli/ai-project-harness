#!/usr/bin/env bash
set -euo pipefail

# Codex CLI Provider Adapter
# Installs Codex-native directories with harness skills, agents, and hooks.
# Usage: adapter.sh <target-project> <harness-dir> [--update]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${2:-$(dirname "$(dirname "$SCRIPT_DIR")")}"
TARGET_PROJECT="${1:-.}"
UPDATE_MODE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

for arg in "$@"; do
    case $arg in
        --update) UPDATE_MODE=true ;;
    esac
done

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    error "Target project does not exist: $TARGET_PROJECT"
    exit 1
}

TEMPLATES_DIR="$HARNESS_DIR/templates"
HARNESS_TARGET="$TARGET_PROJECT/.harness"
CODEX_DIR="$TARGET_PROJECT/.codex"

info "Installing Codex CLI provider adapter..."

# ─── Create .codex/ directory structure ────────────────────────

mkdir -p "$CODEX_DIR/agents"
mkdir -p "$CODEX_DIR/hooks"

# ─── Create AGENTS.md at project root ──────────────────────────

if [ "$UPDATE_MODE" = true ] || [ ! -f "$TARGET_PROJECT/AGENTS.md" ]; then
    cat > "$TARGET_PROJECT/AGENTS.md" << 'AGENTS_EOF'
# Codex Project Instructions

> This file is loaded by Codex when working in this project.

## Project Context

Read `.harness/project-context.md` for project-specific information.

## Memory

This project uses `.harness/memory/` for persistent knowledge:
- `shared/` — durable project knowledge (committed)
- `local/` — temporary session context (gitignored)

## Skills

Available skills are in `.harness/skills/`. They are loaded on demand.

## Agents

Available agent roles are in `.harness/agents/`. They can be dispatched as subagents for specialized work.

## Workflow

1. Before starting work, recall relevant memory from `.harness/memory/shared/`
2. Follow project conventions from `.harness/project-context.md`
3. After completing work, save important findings to project memory
AGENTS_EOF
    info "  Installed AGENTS.md"
else
    info "  AGENTS.md exists (skipping)"
fi

# ─── Create agent TOML files ───────────────────────────────────

info "  Installing agents..."

get_agent_info() {
    local name="$1"
    local field="$2"
    case "$name" in
        orchestrator)
            case "$field" in
                desc) echo "Master orchestrator for complex multi-agent tasks" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,write,glob,grep" ;;
            esac ;;
        planner)
            case "$field" in
                desc) echo "Strategic planner for breaking down complex tasks" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,glob,grep" ;;
            esac ;;
        explorer)
            case "$field" in
                desc) echo "Read-only codebase explorer for quick lookups" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,glob,grep" ;;
            esac ;;
        researcher)
            case "$field" in
                desc) echo "Deep research agent for thorough analysis" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,glob,grep" ;;
            esac ;;
        implementer)
            case "$field" in
                desc) echo "Code implementation agent with write access" ;;
                sandbox) echo "full-access" ;;
                tools) echo "bash,read,write,edit,glob,grep" ;;
            esac ;;
        reviewer)
            case "$field" in
                desc) echo "Code review agent for quality assurance" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,glob,grep" ;;
            esac ;;
        debugger)
            case "$field" in
                desc) echo "Debugging agent for diagnosing issues" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,write,edit,glob,grep" ;;
            esac ;;
        *)
            case "$field" in
                desc) echo "Harness agent" ;;
                sandbox) echo "read-only" ;;
                tools) echo "bash,read,glob,grep" ;;
            esac ;;
    esac
}

for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file" .md)"
        desc="$(get_agent_info "$agent_name" desc)"
        sandbox="$(get_agent_info "$agent_name" sandbox)"
        tools="$(get_agent_info "$agent_name" tools)"

        tools_json=$(echo "$tools" | sed 's/,/, /g' | sed 's/[^,]*/"&"/g')

        cat > "$CODEX_DIR/agents/$agent_name.toml" << TOML_EOF
name = "$agent_name"
description = "$desc"
model = "gpt-5.6-codex"
model_reasoning_effort = "medium"
sandbox_mode = "$sandbox"
disable_response_storage = false

[tools]
enabled = [$tools_json]

developer_instructions = """
$(cat "$agent_file")
"""
TOML_EOF
        info "    Installed agent: $agent_name"
    fi
done
ok "  Agents installed"

# ─── Create hook scripts ───────────────────────────────────────

info "  Installing hooks..."

# Session start hook
cat > "$CODEX_DIR/hooks/session-start.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Codex SessionStart hook
# Reads project context and recalls memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

# Append session started event
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STARTED\",\"provider\":\"codex\"}" >> "$DATA_DIR/events.jsonl"

# Recall memory if available
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md "$MEMORY_DIR"/lessons/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CODEX_DIR/hooks/session-start.sh"
info "    Installed session-start.sh"

# Before task hook
cat > "$CODEX_DIR/hooks/before-task.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Codex UserPromptSubmit hook
# Recalls task-relevant memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-task\",\"provider\":\"codex\"}" >> "$DATA_DIR/events.jsonl"

# Recall task-relevant memory
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CODEX_DIR/hooks/before-task.sh"
info "    Installed before-task.sh"

# After task hook
cat > "$CODEX_DIR/hooks/after-task.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Codex PostToolUse hook
# Evaluates findings and optionally saves to memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"TASK_COMPLETED\",\"hook\":\"after-task\",\"provider\":\"codex\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CODEX_DIR/hooks/after-task.sh"
info "    Installed after-task.sh"

# Before commit hook
cat > "$CODEX_DIR/hooks/before-commit.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Codex PreToolUse hook (for Write/Edit tools)
# Runs verification before file modifications.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-commit\",\"provider\":\"codex\"}" >> "$DATA_DIR/events.jsonl"

# Could run linting, type checking, tests here
# For now, just log the event
HOOK_EOF
chmod +x "$CODEX_DIR/hooks/before-commit.sh"
info "    Installed before-commit.sh"

ok "  Hooks installed"

# ─── Create hooks.json wiring ──────────────────────────────────

cat > "$CODEX_DIR/hooks.json" << HOOKS_JSON_EOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/session-start.sh",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/before-task.sh",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/before-commit.sh",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/after-task.sh",
            "shell": "bash",
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/after-task.sh",
            "shell": "bash",
            "async": true
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CODEX_DIR/hooks/after-task.sh",
            "shell": "bash",
            "async": true
          }
        ]
      }
    ]
  }
}
HOOKS_JSON_EOF
info "  Installed hooks.json"

# ─── Write provider manifest ───────────────────────────────────

cat > "$HARNESS_TARGET/manifest.json" << EOF
{
  "provider": "codex",
  "version": "1.0.0",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
info "  Provider manifest written"

# ─── Verify installation ───────────────────────────────────────

info "Verifying installation..."
ERRORS=0

if [ ! -d "$CODEX_DIR" ]; then
    error "  .codex/ directory not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$TARGET_PROJECT/AGENTS.md" ]; then
    error "  AGENTS.md not created"
    ERRORS=$((ERRORS + 1))
fi

AGENT_COUNT=$(ls "$CODEX_DIR/agents/"*.toml 2>/dev/null | wc -l | xargs)
if [ "$AGENT_COUNT" -ne 7 ]; then
    error "  Expected 7 agents, found $AGENT_COUNT"
    ERRORS=$((ERRORS + 1))
fi

HOOK_COUNT=$(ls "$CODEX_DIR/hooks/"*.sh 2>/dev/null | wc -l | xargs)
if [ "$HOOK_COUNT" -ne 4 ]; then
    error "  Expected 4 hooks, found $HOOK_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CODEX_DIR/hooks.json" ]; then
    error "  hooks.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$HARNESS_TARGET/manifest.json" ]; then
    error "  manifest.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -eq 0 ]; then
    ok "Codex CLI provider adapter installed successfully"
    echo ""
    echo "  Installed components:"
    echo "    AGENTS.md                    — project instructions"
    echo "    .codex/agents/               — $AGENT_COUNT harness agents (TOML)"
    echo "    .codex/hooks/                — $HOOK_COUNT lifecycle hooks"
    echo "    .codex/hooks.json            — hook wiring"
    echo "    .harness/manifest.json       — provider manifest"
else
    error "Codex CLI provider adapter installation failed with $ERRORS errors"
    exit 1
fi
