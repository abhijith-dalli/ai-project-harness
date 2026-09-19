#!/usr/bin/env bash
set -euo pipefail

# OpenCode Provider Adapter
# Installs OpenCode-native directories with harness skills, agents, and hooks.
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

# Parse arguments
PACKS=""
for arg in "$@"; do
    case $arg in
        --update) UPDATE_MODE=true ;;
        --packs) PACKS_NEXT=true ;;
        *)
            if [ "${PACKS_NEXT:-}" = "true" ]; then
                PACKS="$arg"
                unset PACKS_NEXT
            fi
            ;;
    esac
done

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    error "Target project does not exist: $TARGET_PROJECT"
    exit 1
}

TEMPLATES_DIR="$HARNESS_DIR/templates"
HARNESS_TARGET="$TARGET_PROJECT/.harness"
OPENCODE_DIR="$TARGET_PROJECT/.opencode"

info "Installing OpenCode provider adapter..."

# ─── Create .opencode/ directory structure ──────────────────────

mkdir -p "$OPENCODE_DIR/skills"
mkdir -p "$OPENCODE_DIR/agents"
mkdir -p "$OPENCODE_DIR/rules"
mkdir -p "$OPENCODE_DIR/plugins"

# ─── Copy project instructions (AGENTS.md) ─────────────────────

if [ -f "$TEMPLATES_DIR/.opencode/AGENTS.md" ]; then
    if [ "$UPDATE_MODE" = true ] || [ ! -f "$OPENCODE_DIR/AGENTS.md" ]; then
        cp "$TEMPLATES_DIR/.opencode/AGENTS.md" "$OPENCODE_DIR/"
        info "  Installed AGENTS.md"
    else
        info "  AGENTS.md exists (skipping)"
    fi
fi

# ─── Create opencode.json ──────────────────────────────────────

if [ "$UPDATE_MODE" = true ] || [ ! -f "$TARGET_PROJECT/opencode.json" ]; then
    cat > "$TARGET_PROJECT/opencode.json" << 'CONFIG_EOF'
{
  "$schema": "https://opencode.ai/config.json"
}
CONFIG_EOF
    info "  Installed opencode.json"
else
    info "  opencode.json exists (skipping)"
fi

# ─── Copy skills into .opencode/skills/<name>/SKILL.md ─────────

info "  Installing skills..."
for skill_dir in "$TEMPLATES_DIR/.harness/skills/"*; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        target_skill_dir="$OPENCODE_DIR/skills/$skill_name"
        mkdir -p "$target_skill_dir"
        cp "$skill_dir/SKILL.md" "$target_skill_dir/"
        info "    Installed skill: $skill_name"
    fi
done
ok "  Skills installed"

# ─── Copy agents into .opencode/agents/<name>.md ───────────────

info "  Installing agents..."
for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file")"
        cp "$agent_file" "$OPENCODE_DIR/agents/"
        info "    Installed agent: $agent_name"
    fi
done
ok "  Agents installed"

# ─── Copy pack agents into .opencode/agents/ ──────────────────

if [ -n "$PACKS" ]; then
    info "  Installing pack agents..."
    IFS=',' read -ra PACK_ARRAY <<< "$PACKS"
    for pack in "${PACK_ARRAY[@]}"; do
        pack="$(echo "$pack" | xargs)"
        pack_agents="$HARNESS_TARGET/packs/$pack/agents"
        if [ -d "$pack_agents" ]; then
            for agent_file in "$pack_agents/"*.md; do
                if [ -f "$agent_file" ]; then
                    cp "$agent_file" "$OPENCODE_DIR/agents/"
                    info "    Installed pack agent: $(basename "$agent_file")"
                fi
            done
        fi
    done
    ok "  Pack agents installed"
fi

# ─── Create rules/harness.md ───────────────────────────────────

cat > "$OPENCODE_DIR/rules/harness.md" << 'RULES_EOF'
# Harness Integration

This project uses the AI Project Harness for observability and memory.

## Key Paths
- `.harness/project-context.md` — project-specific context
- `.harness/memory/shared/` — durable project knowledge
- `.harness/memory/local/` — temporary session context
- `.harness/hooks/` — lifecycle hook specifications
- `.harness/dashboard/` — observability dashboard

## Workflow
1. Before starting work, recall relevant memory from `.harness/memory/shared/`
2. Follow project conventions from `.harness/project-context.md`
3. After completing work, save important findings to project memory
RULES_EOF
info "  Installed rules/harness.md"

# ─── Copy lifecycle hooks plugin ───────────────────────────────

PLUGIN_TEMPLATE="$SCRIPT_DIR/templates/harness-hooks.js"
if [ -f "$PLUGIN_TEMPLATE" ]; then
    cp "$PLUGIN_TEMPLATE" "$OPENCODE_DIR/plugins/harness-hooks.js"
    info "  Installed plugins/harness-hooks.js"
else
    warn "  Plugin template not found: $PLUGIN_TEMPLATE"
fi

# ─── Write provider manifest ───────────────────────────────────

cat > "$HARNESS_TARGET/manifest.json" << EOF
{
  "provider": "opencode",
  "version": "1.0.0",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
info "  Provider manifest written"

# ─── Verify installation ───────────────────────────────────────

info "Verifying installation..."
ERRORS=0

if [ ! -d "$OPENCODE_DIR" ]; then
    error "  .opencode/ directory not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$OPENCODE_DIR/AGENTS.md" ]; then
    error "  AGENTS.md not created"
    ERRORS=$((ERRORS + 1))
fi

SKILL_COUNT=$(ls -d "$OPENCODE_DIR/skills/"*/ 2>/dev/null | wc -l | xargs)
if [ "$SKILL_COUNT" -ne 17 ]; then
    error "  Expected 17 skills, found $SKILL_COUNT"
    ERRORS=$((ERRORS + 1))
fi

AGENT_COUNT=$(ls "$OPENCODE_DIR/agents/"*.md 2>/dev/null | wc -l | xargs)
if [ "$AGENT_COUNT" -ne 7 ]; then
    error "  Expected 7 agents, found $AGENT_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$OPENCODE_DIR/plugins/harness-hooks.js" ]; then
    error "  harness-hooks.js not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$TARGET_PROJECT/opencode.json" ]; then
    error "  opencode.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$HARNESS_TARGET/manifest.json" ]; then
    error "  manifest.json not created"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -eq 0 ]; then
    ok "OpenCode provider adapter installed successfully"
    echo ""
    echo "  Installed components:"
    echo "    .opencode/AGENTS.md         — project instructions"
    echo "    .opencode/skills/           — $SKILL_COUNT harness skills"
    echo "    .opencode/agents/           — $AGENT_COUNT harness agents"
    echo "    .opencode/rules/harness.md  — harness integration rules"
    echo "    .opencode/plugins/          — lifecycle hooks plugin"
    echo "    opencode.json               — OpenCode config"
    echo "    .harness/manifest.json      — provider manifest"
else
    error "OpenCode provider adapter installation failed with $ERRORS errors"
    exit 1
fi
