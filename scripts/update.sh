#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness Updater
# Updates harness-managed files while preserving project-specific data.
# Usage: ./update.sh /path/to/project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$HARNESS_DIR/templates"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

TARGET_PROJECT="${1:-}"

if [ -z "$TARGET_PROJECT" ]; then
    echo "Usage: $0 <target-project-path>"
    exit 1
fi

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    error "Target project does not exist: $TARGET_PROJECT"
    exit 1
}

HARNESS_TARGET="$TARGET_PROJECT/.harness"

if [ ! -d "$HARNESS_TARGET" ]; then
    error "No .harness/ directory found in $TARGET_PROJECT"
    error "Run install.sh first"
    exit 1
fi

info "Updating harness in: $TARGET_PROJECT"

# ─── Update agents (overwrite harness-owned, preserve custom) ─────

info "Updating agents..."
for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file")"
        target="$HARNESS_TARGET/agents/$agent_name"
        if [ -f "$target" ]; then
            # Check if it was customized (different from template)
            if ! diff -q "$agent_file" "$target" &>/dev/null; then
                warn "  Agent customized (preserving): $agent_name"
            else
                cp "$agent_file" "$target"
                info "  Updated agent: $agent_name"
            fi
        else
            cp "$agent_file" "$target"
            info "  Installed new agent: $agent_name"
        fi
    fi
done
ok "Agents updated"

# ─── Update skills (overwrite harness-owned, preserve custom) ────

info "Updating skills..."
for skill_dir in "$TEMPLATES_DIR/.harness/skills/"*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        target="$HARNESS_TARGET/skills/$skill_name"
        if [ -d "$target" ]; then
            if ! diff -q "$skill_dir/SKILL.md" "$target/SKILL.md" &>/dev/null; then
                warn "  Skill customized (preserving): $skill_name"
            else
                cp -r "$skill_dir" "$target"
                info "  Updated skill: $skill_name"
            fi
        else
            cp -r "$skill_dir" "$target"
            info "  Installed new skill: $skill_name"
        fi
    fi
done
ok "Skills updated"

# ─── Update hooks (always overwrite — these are harness-owned) ───

info "Updating hooks..."
for hook_file in "$TEMPLATES_DIR/.harness/hooks/"*.md; do
    if [ -f "$hook_file" ]; then
        hook_name="$(basename "$hook_file")"
        cp "$hook_file" "$HARNESS_TARGET/hooks/"
        info "  Updated hook: $hook_name"
    fi
done
ok "Hooks updated"

# ─── Update dashboard (always overwrite — UI is harness-owned) ───

info "Updating dashboard..."
mkdir -p "$HARNESS_TARGET/dashboard"
for dashboard_file in "$TEMPLATES_DIR/.harness/dashboard/"*; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name="$(basename "$dashboard_file")"
        cp "$dashboard_file" "$HARNESS_TARGET/dashboard/"
        info "  Updated: $dashboard_name"
    fi
done
ok "Dashboard updated"

# ─── Update data files (always overwrite — template data) ────────

info "Updating data files..."
for data_file in "$TEMPLATES_DIR/.harness/data/"*.jsonl; do
    if [ -f "$data_file" ]; then
        data_name="$(basename "$data_file")"
        cp "$data_file" "$HARNESS_TARGET/data/"
        info "  Updated: $data_name"
    fi
done
ok "Data files updated"

# ─── Update provider adapter ────────────────────────────────────

PROVIDERS_DIR="$HARNESS_DIR/providers"
PROVIDER=""
if [ -f "$HARNESS_TARGET/manifest.json" ]; then
    PROVIDER=$(grep -o '"provider": *"[^"]*"' "$HARNESS_TARGET/manifest.json" | cut -d'"' -f4)
fi

if [ -n "$PROVIDER" ] && [ -d "$PROVIDERS_DIR/$PROVIDER" ]; then
    info "Updating provider adapter: $PROVIDER"
    bash "$PROVIDERS_DIR/$PROVIDER/adapter.sh" "$TARGET_PROJECT" "$HARNESS_DIR" --update
else
    warn "No provider adapter found to update"
fi

# ─── DO NOT touch these ──────────────────────────────────────────

info "Preserving project-specific data:"
info "  .harness/project-context.md — not touched"
info "  .harness/memory/ — not touched"
info "  .harness/config/ — not touched (review for new options)"
info "  .harness/packs/ — not touched"

# ─── Summary ──────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Harness Updated!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Harness version: $(cat "$HARNESS_DIR/VERSION" 2>/dev/null || echo 'unknown')"
echo "  Run doctor.sh to verify: ./scripts/doctor.sh $TARGET_PROJECT"
echo ""
