#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness Installer
# Installs the reusable harness into a target project.
# Usage: ./install.sh /path/to/project [OPTIONS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$HARNESS_DIR/templates"
PROVIDERS_DIR="$HARNESS_DIR/providers"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    echo "Usage: $0 <target-project-path> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --provider <name>       AI provider (opencode, claude, cursor, codex)"
    echo "  --packs <packs>         Enable specialist packs (comma-separated)"
    echo "  --help                  Show this help"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/MyProject --provider opencode"
    echo "  $0 /path/to/MyProject --provider claude --packs backend,database"
    exit 0
}

TARGET_PROJECT=""
PROVIDER=""
PACKS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --provider) PROVIDER="$2"; shift 2 ;;
        --packs) PACKS="$2"; shift 2 ;;
        --help) usage ;;
        -*) error "Unknown option: $1"; usage ;;
        *) TARGET_PROJECT="$1"; shift ;;
    esac
done

if [ -z "$TARGET_PROJECT" ]; then
    error "Target project path is required"
    usage
fi

# ─── Interactive provider selection ─────────────────────────────

if [ -z "$PROVIDER" ]; then
    echo ""
    echo "Select AI provider:"
    echo "  1) OpenCode"
    echo "  2) Claude Code"
    echo "  3) Cursor"
    echo "  4) Codex"
    echo ""
    read -r -p "Enter choice [1-4]: " choice
    case $choice in
        1) PROVIDER="opencode" ;;
        2) PROVIDER="claude" ;;
        3) PROVIDER="cursor" ;;
        4) PROVIDER="codex" ;;
        *) error "Invalid choice: $choice"; usage ;;
    esac
fi

# Validate provider
case $PROVIDER in
    opencode|claude|cursor|codex) ;;
    *) error "Invalid provider: $PROVIDER (must be opencode, claude, cursor, or codex)"; usage ;;
esac

if [ ! -d "$PROVIDERS_DIR/$PROVIDER" ]; then
    error "Provider adapter not found: $PROVIDER"
    exit 1
fi

info "Using provider: $PROVIDER"

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    error "Target project does not exist: $TARGET_PROJECT"
    exit 1
}

info "Installing AI Project Harness into: $TARGET_PROJECT"

if [ ! -d "$TARGET_PROJECT" ]; then
    error "Target directory does not exist: $TARGET_PROJECT"
    exit 1
fi

# ─── Detect Git ────────────────────────────────────────────────────

IS_GIT_REPO=false
if command -v git &>/dev/null && git -C "$TARGET_PROJECT" rev-parse --git-dir &>/dev/null; then
    IS_GIT_REPO=true
    ok "Git repository detected"
else
    warn "Not a Git repository — memory isolation will use directory name"
fi

PROJECT_NAME=""
if $IS_GIT_REPO; then
    PROJECT_NAME="$(basename "$(git -C "$TARGET_PROJECT" rev-parse --show-toplevel)")"
else
    PROJECT_NAME="$(basename "$TARGET_PROJECT")"
fi
info "Project name: $PROJECT_NAME"

# ─── Create .harness/ directory structure ──────────────────────────

info "Creating .harness/ directory structure..."

HARNESS_TARGET="$TARGET_PROJECT/.harness"

mkdir -p "$HARNESS_TARGET/agents"
mkdir -p "$HARNESS_TARGET/skills"
mkdir -p "$HARNESS_TARGET/hooks"
mkdir -p "$HARNESS_TARGET/config"
mkdir -p "$HARNESS_TARGET/data"
mkdir -p "$HARNESS_TARGET/dashboard"
mkdir -p "$HARNESS_TARGET/memory/shared/project"
mkdir -p "$HARNESS_TARGET/memory/shared/decisions"
mkdir -p "$HARNESS_TARGET/memory/shared/lessons"
mkdir -p "$HARNESS_TARGET/memory/shared/observations"
mkdir -p "$HARNESS_TARGET/memory/local/sessions"

ok "Directory structure created"

# ─── Copy agents (always overwrite — harness-owned) ──────────────

info "Installing agents..."
for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file")"
        cp "$agent_file" "$HARNESS_TARGET/agents/"
        info "  Installed agent: $agent_name"
    fi
done
ok "Agents installed"

# ─── Copy skills (always overwrite — harness-owned) ──────────────

info "Installing skills..."
for skill_dir in "$TEMPLATES_DIR/.harness/skills/"*; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        cp -r "$skill_dir" "$HARNESS_TARGET/skills/"
        info "  Installed skill: $skill_name"
    fi
done
ok "Skills installed"

# ─── Copy hooks (always overwrite — harness-owned) ───────────────

info "Installing hooks..."
for hook_file in "$TEMPLATES_DIR/.harness/hooks/"*.md; do
    if [ -f "$hook_file" ]; then
        hook_name="$(basename "$hook_file")"
        cp "$hook_file" "$HARNESS_TARGET/hooks/"
        info "  Installed hook: $hook_name"
    fi
done
ok "Hooks installed"

# ─── Copy config ──────────────────────────────────────────────────

info "Installing configuration..."
if [ ! -f "$HARNESS_TARGET/config/harness.yaml" ]; then
    cp "$TEMPLATES_DIR/.harness/config/harness.yaml" "$HARNESS_TARGET/config/"
    info "  Installed harness.yaml"
else
    info "  Config exists (skipping)"
fi

if [ ! -f "$HARNESS_TARGET/project-context.md" ]; then
    cp "$TEMPLATES_DIR/.harness/project-context.md" "$HARNESS_TARGET/"
    info "  Installed project-context.md"
else
    info "  project-context.md exists (skipping)"
fi

# ─── Copy runtime data files (always overwrite) ──────────────────

info "Installing runtime data files..."
for data_file in "$TEMPLATES_DIR/.harness/data/"*.jsonl; do
    if [ -f "$data_file" ]; then
        data_name="$(basename "$data_file")"
        cp "$data_file" "$HARNESS_TARGET/data/"
        info "  Installed: $data_name"
    fi
done
ok "Runtime data files installed"

# ─── Copy dashboard (always overwrite — UI is harness-owned) ─────

info "Installing dashboard..."
for dashboard_file in "$TEMPLATES_DIR/.harness/dashboard/"*; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name="$(basename "$dashboard_file")"
        cp "$dashboard_file" "$HARNESS_TARGET/dashboard/"
        info "  Installed: $dashboard_name"
    fi
done
ok "Dashboard installed"

# ─── Copy memory READMEs ─────────────────────────────────────────

for readme in shared/README.md local/README.md shared/project/README.md shared/decisions/README.md shared/lessons/README.md shared/observations/README.md; do
    src="$TEMPLATES_DIR/.harness/memory/$readme"
    dst="$HARNESS_TARGET/memory/$readme"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
    fi
done
ok "Configuration installed"

# ─── Copy VERSION ─────────────────────────────────────────────────

if [ -f "$HARNESS_DIR/VERSION" ]; then
    cp "$HARNESS_DIR/VERSION" "$HARNESS_TARGET/"
    info "  Installed VERSION"
fi

# ─── Enable specialist packs ──────────────────────────────────────

if [ -n "$PACKS" ]; then
    info "Enabling specialist packs: $PACKS"
    IFS=',' read -ra PACK_ARRAY <<< "$PACKS"
    for pack in "${PACK_ARRAY[@]}"; do
        pack="$(echo "$pack" | xargs)"
        pack_src="$HARNESS_DIR/packs/$pack"
        if [ -d "$pack_src" ]; then
            mkdir -p "$HARNESS_TARGET/packs/$pack"
            cp -r "$pack_src"/* "$HARNESS_TARGET/packs/$pack/" 2>/dev/null || true
            info "  Enabled pack: $pack"
        else
            warn "  Pack not found: $pack"
        fi
    done
fi

# ─── Install provider adapter (selected provider only) ──────────

info "Installing provider adapter: $PROVIDER"
bash "$PROVIDERS_DIR/$PROVIDER/adapter.sh" "$TARGET_PROJECT" "$HARNESS_DIR" ${PACKS:+--packs "$PACKS"}

# ─── Update .gitignore ────────────────────────────────────────────

info "Updating .gitignore..."
GITIGNORE="$TARGET_PROJECT/.gitignore"

GITIGNORE_ENTRIES=(
    ".harness/memory/local/"
    ".harness/packs/"
    ".harness/agents/"
    ".harness/skills/"
    ".harness/hooks/"
    ".harness/data/"
    ".harness/dashboard/"
    ".harness/config/"
)

# Add provider-specific entries
case $PROVIDER in
    opencode)
        GITIGNORE_ENTRIES+=(".opencode/" "opencode.json")
        ;;
    claude)
        GITIGNORE_ENTRIES+=(".claude/")
        ;;
    cursor)
        GITIGNORE_ENTRIES+=(".cursor/")
        ;;
    codex)
        GITIGNORE_ENTRIES+=(".codex/" "AGENTS.md")
        ;;
esac

for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if [ -f "$GITIGNORE" ]; then
        if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
            echo "" >> "$GITIGNORE"
            echo "# AI Project Harness" >> "$GITIGNORE"
            echo "$entry" >> "$GITIGNORE"
        fi
    else
        echo "# AI Project Harness" > "$GITIGNORE"
        echo "$entry" >> "$GITIGNORE"
    fi
done
ok ".gitignore updated"

# ─── Summary ──────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  AI Project Harness Installed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Project: $PROJECT_NAME"
echo "  Location: $TARGET_PROJECT"
echo "  Provider: $PROVIDER"
echo ""
echo "  Installed components:"
echo "    .harness/agents/       — $(ls "$HARNESS_TARGET/agents/"*.md 2>/dev/null | wc -l | xargs) agents"
echo "    .harness/skills/       — $(ls -d "$HARNESS_TARGET/skills/"*/ 2>/dev/null | wc -l | xargs) skills"
echo "    .harness/hooks/        — $(ls "$HARNESS_TARGET/hooks/"*.md 2>/dev/null | wc -l | xargs) hooks"
echo "    .harness/memory/       — shared + local directories"
echo "    .harness/data/         — runtime data files"
echo "    .harness/dashboard/    — observability dashboard"
case $PROVIDER in
    opencode)  echo "    .opencode/            — OpenCode adapter" ;;
    claude)    echo "    .claude/               — Claude Code adapter" ;;
    cursor)    echo "    .cursor/               — Cursor adapter" ;;
    codex)     echo "    .codex/                — Codex CLI adapter" ;;
esac
echo ""
echo "  Next steps:"
echo "    1. Fill in .harness/project-context.md"
echo "    2. Run ./scripts/doctor.sh $TARGET_PROJECT"
echo "    3. Open the project with your AI agent"
echo "    4. View dashboard: ./scripts/serve-dashboard.sh $TARGET_PROJECT"
echo ""
