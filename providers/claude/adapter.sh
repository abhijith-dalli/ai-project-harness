#!/usr/bin/env bash
set -euo pipefail

# Claude Code Provider Adapter
# Installs Claude Code-native directories with harness skills, agents, and hooks.
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
CLAUDE_DIR="$TARGET_PROJECT/.claude"

info "Installing Claude Code provider adapter..."

# ─── Create .claude/ directory structure ───────────────────────

mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/hooks"

# ─── Copy CLAUDE.md (project instructions) ─────────────────────

if [ -f "$TEMPLATES_DIR/.claude/CLAUDE.md" ]; then
    if [ "$UPDATE_MODE" = true ] || [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$TEMPLATES_DIR/.claude/CLAUDE.md" "$CLAUDE_DIR/"
        info "  Installed CLAUDE.md"
    else
        info "  CLAUDE.md exists (skipping)"
    fi
fi

# ─── Copy settings.json ────────────────────────────────────────

if [ -f "$TEMPLATES_DIR/.claude/settings.json" ]; then
    if [ "$UPDATE_MODE" = true ] || [ ! -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$TEMPLATES_DIR/.claude/settings.json" "$CLAUDE_DIR/"
        info "  Installed settings.json"
    else
        info "  settings.json exists (skipping)"
    fi
fi

# ─── Copy skills into .claude/skills/<name>/SKILL.md ───────────

info "  Installing skills..."
for skill_dir in "$TEMPLATES_DIR/.harness/skills/"*; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        target_skill_dir="$CLAUDE_DIR/skills/$skill_name"
        mkdir -p "$target_skill_dir"
        cp "$skill_dir/SKILL.md" "$target_skill_dir/"
        info "    Installed skill: $skill_name"
    fi
done
ok "  Skills installed"

# ─── Copy agents into .claude/agents/<name>.md ─────────────────

info "  Installing agents..."
for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file" .md)"
        cp "$agent_file" "$CLAUDE_DIR/agents/"
        info "    Installed agent: $agent_name"
    fi
done
ok "  Agents installed"

# ─── Create hook scripts ───────────────────────────────────────

info "  Installing hooks..."

# Session start hook
cat > "$CLAUDE_DIR/hooks/session-start.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code SessionStart hook
# Reads project context and recalls memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

# Append session started event
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STARTED\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"

# Recall memory if available
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md "$MEMORY_DIR"/lessons/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/session-start.sh"
info "    Installed session-start.sh"

# Prompt submit hook
cat > "$CLAUDE_DIR/hooks/prompt-submit.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code UserPromptSubmit hook
# Recalls task-relevant memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"
MEMORY_DIR="$HARNESS_DIR/memory/shared"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-task\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"

# Recall task-relevant memory
if [ -d "$MEMORY_DIR" ]; then
    for f in "$MEMORY_DIR"/decisions/*.md; do
        [ -f "$f" ] && cat "$f" 2>/dev/null
    done
fi
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/prompt-submit.sh"
info "    Installed prompt-submit.sh"

# Pre-tool-use hook
cat > "$CLAUDE_DIR/hooks/pre-tool-use.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code PreToolUse hook
# Runs verification before file modifications.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"HOOK_STARTED\",\"hook\":\"before-commit\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"

# Could run linting, type checking, tests here
# For now, just log the event
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/pre-tool-use.sh"
info "    Installed pre-tool-use.sh"

# Post-tool-use hook
cat > "$CLAUDE_DIR/hooks/post-tool-use.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code PostToolUse hook
# Evaluates findings and optionally saves to memory.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"TASK_COMPLETED\",\"hook\":\"after-task\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/post-tool-use.sh"
info "    Installed post-tool-use.sh"

# Stop hook
cat > "$CLAUDE_DIR/hooks/stop.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code Stop hook
# Session end cleanup.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_STOPPED\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/stop.sh"
info "    Installed stop.sh"

# Session end hook
cat > "$CLAUDE_DIR/hooks/session-end.sh" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# Claude Code SessionEnd hook
# Final cleanup.

HARNESS_DIR="$(pwd)/.harness"
DATA_DIR="$HARNESS_DIR/data"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"SESSION_ENDED\",\"provider\":\"claude\"}" >> "$DATA_DIR/events.jsonl"
HOOK_EOF
chmod +x "$CLAUDE_DIR/hooks/session-end.sh"
info "    Installed session-end.sh"

ok "  Hooks installed"

# ─── Create hooks.json wiring ──────────────────────────────────

CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"

cat > "$CLAUDE_DIR/hooks.json" << HOOKS_JSON_EOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_HOOKS_DIR/session-start.sh",
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
            "command": "$CLAUDE_HOOKS_DIR/prompt-submit.sh",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_HOOKS_DIR/pre-tool-use.sh",
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
            "command": "$CLAUDE_HOOKS_DIR/post-tool-use.sh",
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
            "command": "$CLAUDE_HOOKS_DIR/stop.sh",
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
            "command": "$CLAUDE_HOOKS_DIR/session-end.sh",
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
  "provider": "claude",
  "version": "1.0.0",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
info "  Provider manifest written"

# ─── Verify installation ───────────────────────────────────────

info "Verifying installation..."
ERRORS=0

if [ ! -d "$CLAUDE_DIR" ]; then
    error "  .claude/ directory not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    error "  CLAUDE.md not created"
    ERRORS=$((ERRORS + 1))
fi

SKILL_COUNT=$(ls -d "$CLAUDE_DIR/skills/"*/ 2>/dev/null | wc -l | xargs)
if [ "$SKILL_COUNT" -ne 17 ]; then
    error "  Expected 17 skills, found $SKILL_COUNT"
    ERRORS=$((ERRORS + 1))
fi

AGENT_COUNT=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l | xargs)
if [ "$AGENT_COUNT" -ne 7 ]; then
    error "  Expected 7 agents, found $AGENT_COUNT"
    ERRORS=$((ERRORS + 1))
fi

HOOK_COUNT=$(ls "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null | wc -l | xargs)
if [ "$HOOK_COUNT" -ne 6 ]; then
    error "  Expected 6 hooks, found $HOOK_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$CLAUDE_DIR/hooks.json" ]; then
    error "  hooks.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$HARNESS_TARGET/manifest.json" ]; then
    error "  manifest.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -eq 0 ]; then
    ok "Claude Code provider adapter installed successfully"
    echo ""
    echo "  Installed components:"
    echo "    .claude/CLAUDE.md           — project instructions"
    echo "    .claude/settings.json       — Claude Code settings"
    echo "    .claude/skills/             — $SKILL_COUNT harness skills"
    echo "    .claude/agents/             — $AGENT_COUNT harness agents"
    echo "    .claude/hooks/              — $HOOK_COUNT lifecycle hooks"
    echo "    .claude/hooks.json          — hook wiring"
    echo "    .harness/manifest.json      — provider manifest"
else
    error "Claude Code provider adapter installation failed with $ERRORS errors"
    exit 1
fi
