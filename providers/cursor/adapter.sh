#!/usr/bin/env bash
set -euo pipefail

# Cursor Provider Adapter
# Installs Cursor-native directories with harness skills, agents, and hooks.
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
CURSOR_DIR="$TARGET_PROJECT/.cursor"

info "Installing Cursor provider adapter..."

# ─── Create .cursor/ directory structure ───────────────────────

mkdir -p "$CURSOR_DIR/rules"
mkdir -p "$CURSOR_DIR/hooks"

# ─── Copy .cursorrules (backward compatible) ───────────────────

if [ -f "$TEMPLATES_DIR/.cursor/.cursorrules" ]; then
    if [ "$UPDATE_MODE" = true ] || [ ! -f "$CURSOR_DIR/.cursorrules" ]; then
        cp "$TEMPLATES_DIR/.cursor/.cursorrules" "$CURSOR_DIR/"
        info "  Installed .cursorrules"
    else
        info "  .cursorrules exists (skipping)"
    fi
fi

# ─── Copy mcp.json ─────────────────────────────────────────────

if [ -f "$TEMPLATES_DIR/.cursor/mcp.json" ]; then
    if [ "$UPDATE_MODE" = true ] || [ ! -f "$CURSOR_DIR/mcp.json" ]; then
        cp "$TEMPLATES_DIR/.cursor/mcp.json" "$CURSOR_DIR/"
        info "  Installed mcp.json"
    else
        info "  mcp.json exists (skipping)"
    fi
fi

# ─── Create rules/harness.md ───────────────────────────────────

cat > "$CURSOR_DIR/rules/harness.md" << 'RULES_EOF'
# Harness Integration

This project uses the AI Project Harness for observability and memory.

## Key Paths
- `.harness/project-context.md` — project-specific context
- `.harness/memory/shared/` — durable project knowledge
- `.harness/memory/local/` — temporary session context
- `.harness/hooks/` — lifecycle hook specifications
- `.harness/dashboard/` — observability dashboard
- `.harness/skills/` — available skills (load via skill tool)
- `.harness/agents/` — available agents (dispatch as subagents)

## Workflow
1. Before starting work, recall relevant memory from `.harness/memory/shared/`
2. Follow project conventions from `.harness/project-context.md`
3. After completing work, save important findings to project memory
RULES_EOF
info "  Installed rules/harness.md"

# ─── Create hook scripts ───────────────────────────────────────

info "  Installing hooks..."

# Session start hook
cat > "$CURSOR_DIR/hooks/session-start.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor sessionStart hook
# Reads project context and recalls memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

# Append session started event
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STARTED\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"

# Recall memory if available
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md "$MEMORY_DIR"/lessons/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/session-start.sh"
info "    Installed session-start.sh"

# Prompt submit hook
cat > "$CURSOR_DIR/hooks/prompt-submit.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor beforeSubmitPrompt hook
# Recalls task-relevant memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-task\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"

# Recall task-relevant memory
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/prompt-submit.sh"
info "    Installed prompt-submit.sh"

# Pre-tool-use hook
cat > "$CURSOR_DIR/hooks/pre-tool-use.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor preToolUse hook
# Runs verification before file modifications.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-commit\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"

# Could run linting, type checking, tests here
# For now, just log the event
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/pre-tool-use.sh"
info "    Installed pre-tool-use.sh"

# Post-tool-use hook
cat > "$CURSOR_DIR/hooks/post-tool-use.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor postToolUse hook
# Evaluates findings and optionally saves to memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"TASK_COMPLETED\",\"hook\":\"after-task\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/post-tool-use.sh"
info "    Installed post-tool-use.sh"

# Stop hook
cat > "$CURSOR_DIR/hooks/stop.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor stop hook
# Session end cleanup.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STOPPED\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/stop.sh"
info "    Installed stop.sh"

# Session end hook
cat > "$CURSOR_DIR/hooks/session-end.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Cursor sessionEnd hook
# Final cleanup.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_ENDED\",\"provider\":\"cursor\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CURSOR_DIR/hooks/session-end.sh"
info "    Installed session-end.sh"

ok "  Hooks installed"

# ─── Create hooks.json wiring ──────────────────────────────────

CURSOR_HOOKS_DIR="$CURSOR_DIR/hooks"

cat > "$CURSOR_DIR/hooks.json" << HOOKS_JSON_EOF
{
  "hooks": {
    "sessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/session-start.sh",
            "shell": "bash"
          }
        ]
      }
    ],
    "beforeSubmitPrompt": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/prompt-submit.sh",
            "shell": "bash"
          }
        ]
      }
    ],
    "preToolUse": [
      {
        "matcher": "Shell|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/pre-tool-use.sh",
            "shell": "bash"
          }
        ]
      }
    ],
    "postToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/post-tool-use.sh",
            "shell": "bash"
          }
        ]
      }
    ],
    "stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/stop.sh",
            "shell": "bash"
          }
        ]
      }
    ],
    "sessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CURSOR_HOOKS_DIR/session-end.sh",
            "shell": "bash"
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
  "provider": "cursor",
  "version": "1.0.0",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
info "  Provider manifest written"

# ─── Verify installation ───────────────────────────────────────

info "Verifying installation..."
ERRORS=0

if [ ! -d "$CURSOR_DIR" ]; then
    error "  .cursor/ directory not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CURSOR_DIR/.cursorrules" ]; then
    error "  .cursorrules not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CURSOR_DIR/rules/harness.md" ]; then
    error "  rules/harness.md not created"
    ERRORS=$((ERRORS + 1))
fi

HOOK_COUNT=$(ls "$CURSOR_DIR/hooks/"*.sh 2>/dev/null | wc -l | xargs)
if [ "$HOOK_COUNT" -ne 6 ]; then
    error "  Expected 6 hooks, found $HOOK_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CURSOR_DIR/hooks.json" ]; then
    error "  hooks.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CURSOR_DIR/mcp.json" ]; then
    error "  mcp.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$HARNESS_TARGET/manifest.json" ]; then
    error "  manifest.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -eq 0 ]; then
    ok "Cursor provider adapter installed successfully"
    echo ""
    echo "  Installed components:"
    echo "    .cursor/.cursorrules        — project rules (backward compat)"
    echo "    .cursor/rules/harness.md    — harness integration rules"
    echo "    .cursor/hooks/              — $HOOK_COUNT lifecycle hooks"
    echo "    .cursor/hooks.json          — hook wiring"
    echo "    .cursor/mcp.json            — MCP config"
    echo "    .harness/manifest.json      — provider manifest"
    echo ""
    echo "  Note: Cursor does not support native skills/agents directories."
    echo "  Skills and agents are referenced from .harness/ via rules."
else
    error "Cursor provider adapter installation failed with $ERRORS errors"
    exit 1
fi
