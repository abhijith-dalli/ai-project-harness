#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness Installer
# Installs the reusable harness into a target project.
# Usage: ./install.sh /path/to/project [--enable-agentmemory]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$HARNESS_DIR/templates"

# Colors
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
    echo "  --enable-agentmemory    Enable optional agentmemory integration"
    echo "  --enable-cursor         Enable Cursor adapter"
    echo "  --enable-codex          Enable Codex CLI adapter"
    echo "  --packs <packs>         Enable specialist packs (comma-separated)"
    echo "  --help                  Show this help"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/MyProject"
    echo "  $0 /path/to/MyProject --enable-agentmemory --packs backend,database"
    exit 0
}

# Parse arguments
TARGET_PROJECT=""
ENABLE_AGENTMEMORY=false
ENABLE_CURSOR=false
ENABLE_CODEX=false
PACKS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-agentmemory) ENABLE_AGENTMEMORY=true; shift ;;
        --enable-cursor) ENABLE_CURSOR=true; shift ;;
        --enable-codex) ENABLE_CODEX=true; shift ;;
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

# Resolve to absolute path
TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    error "Target project does not exist: $TARGET_PROJECT"
    exit 1
}

info "Installing AI Project Harness into: $TARGET_PROJECT"

# ─── Validate target project ───────────────────────────────────────

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

# ─── Detect project name ──────────────────────────────────────────

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

# Core directories
mkdir -p "$HARNESS_TARGET/agents"
mkdir -p "$HARNESS_TARGET/skills"
mkdir -p "$HARNESS_TARGET/hooks"
mkdir -p "$HARNESS_TARGET/config"
mkdir -p "$HARNESS_TARGET/adapters"
mkdir -p "$HARNESS_TARGET/memory/shared/project"
mkdir -p "$HARNESS_TARGET/memory/shared/decisions"
mkdir -p "$HARNESS_TARGET/memory/shared/lessons"
mkdir -p "$HARNESS_TARGET/memory/shared/observations"
mkdir -p "$HARNESS_TARGET/memory/local/sessions"

ok "Directory structure created"

# ─── Copy agents ──────────────────────────────────────────────────

info "Installing agents..."
for agent_file in "$TEMPLATES_DIR/.harness/agents/"*.md; do
    if [ -f "$agent_file" ]; then
        agent_name="$(basename "$agent_file")"
        if [ ! -f "$HARNESS_TARGET/agents/$agent_name" ]; then
            cp "$agent_file" "$HARNESS_TARGET/agents/"
            info "  Installed agent: $agent_name"
        else
            info "  Agent exists (skipping): $agent_name"
        fi
    fi
done
ok "Agents installed"

# ─── Copy skills ──────────────────────────────────────────────────

info "Installing skills..."
for skill_dir in "$TEMPLATES_DIR/.harness/skills/"*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        if [ ! -d "$HARNESS_TARGET/skills/$skill_name" ]; then
            cp -r "$skill_dir" "$HARNESS_TARGET/skills/"
            info "  Installed skill: $skill_name"
        else
            info "  Skill exists (skipping): $skill_name"
        fi
    fi
done
ok "Skills installed"

# ─── Copy hooks ───────────────────────────────────────────────────

info "Installing hooks..."
for hook_file in "$TEMPLATES_DIR/.harness/hooks/"*.md; do
    if [ -f "$hook_file" ]; then
        hook_name="$(basename "$hook_file")"
        if [ ! -f "$HARNESS_TARGET/hooks/$hook_name" ]; then
            cp "$hook_file" "$HARNESS_TARGET/hooks/"
            info "  Installed hook: $hook_name"
        else
            info "  Hook exists (skipping): $hook_name"
        fi
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

# ─── Copy project context ────────────────────────────────────────

if [ ! -f "$HARNESS_TARGET/project-context.md" ]; then
    cp "$TEMPLATES_DIR/.harness/project-context.md" "$HARNESS_TARGET/"
    info "  Installed project-context.md"
else
    info "  project-context.md exists (skipping)"
fi

# ─── Copy memory READMEs ─────────────────────────────────────────

for readme in shared/README.md local/README.md shared/project/README.md shared/decisions/README.md shared/lessons/README.md shared/observations/README.md; do
    src="$TEMPLATES_DIR/.harness/memory/$readme"
    dst="$HARNESS_TARGET/memory/$readme"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
    fi
done
ok "Configuration installed"

# ─── Install provider adapters ────────────────────────────────────

info "Installing provider adapters..."

# Claude Code adapter (always installed)
if [ ! -d "$TARGET_PROJECT/.claude" ]; then
    mkdir -p "$TARGET_PROJECT/.claude"
fi
cp "$TEMPLATES_DIR/.claude/settings.json" "$TARGET_PROJECT/.claude/" 2>/dev/null || true
cp "$TEMPLATES_DIR/.claude/hooks.json" "$TARGET_PROJECT/.claude/" 2>/dev/null || true
cp "$TEMPLATES_DIR/.claude/CLAUDE.md" "$TARGET_PROJECT/.claude/" 2>/dev/null || true
ok "  Claude Code adapter installed"

# OpenCode adapter (always installed)
cp "$TEMPLATES_DIR/opencode.json" "$TARGET_PROJECT/" 2>/dev/null || true
mkdir -p "$TARGET_PROJECT/.opencode"
cp "$TEMPLATES_DIR/.opencode/AGENTS.md" "$TARGET_PROJECT/.opencode/" 2>/dev/null || true
ok "  OpenCode adapter installed"

# Cursor adapter (optional)
if $ENABLE_CURSOR; then
    if [ ! -d "$TARGET_PROJECT/.cursor" ]; then
        mkdir -p "$TARGET_PROJECT/.cursor"
    fi
    cp "$TEMPLATES_DIR/.cursor/mcp.json" "$TARGET_PROJECT/.cursor/" 2>/dev/null || true
    cp "$TEMPLATES_DIR/.cursor/hooks.json" "$TARGET_PROJECT/.cursor/" 2>/dev/null || true
    cp "$TEMPLATES_DIR/.cursor/.cursorrules" "$TARGET_PROJECT/.cursor/" 2>/dev/null || true
    ok "  Cursor adapter installed"
fi

# Codex CLI adapter (optional)
if $ENABLE_CODEX; then
    mkdir -p "$TARGET_PROJECT/.agents/plugins"
    cp "$TEMPLATES_DIR/.agents/mcp.json" "$TARGET_PROJECT/.agents/" 2>/dev/null || true
    ok "  Codex CLI adapter installed"
fi

# ─── Enable specialist packs ──────────────────────────────────────

if [ -n "$PACKS" ]; then
    info "Enabling specialist packs: $PACKS"
    IFS=',' read -ra PACK_ARRAY <<< "$PACKS"
    for pack in "${PACK_ARRAY[@]}"; do
        pack="$(echo "$pack" | xargs)"  # trim whitespace
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

# ─── Configure agentmemory (optional) ─────────────────────────────

if $ENABLE_AGENTMEMORY; then
    info "Configuring agentmemory integration..."
    if command -v npx &>/dev/null; then
        info "  Checking agentmemory installation..."
        if npx -y @agentmemory/agentmemory --version &>/dev/null 2>&1; then
            ok "  agentmemory is available"
        else
            warn "  agentmemory not found — will install on first use"
        fi
    else
        warn "  npx not found — agentmemory requires Node.js"
    fi

    # Update harness config to enable agentmemory
    if [ -f "$HARNESS_TARGET/config/harness.yaml" ]; then
        sed -i.bak 's/enabled: false/enabled: true/' "$HARNESS_TARGET/config/harness.yaml" 2>/dev/null || \
        sed -i '' 's/enabled: false/enabled: true/' "$HARNESS_TARGET/config/harness.yaml" 2>/dev/null || true
        rm -f "$HARNESS_TARGET/config/harness.yaml.bak"
    fi
fi

# ─── Update .gitignore ────────────────────────────────────────────

info "Updating .gitignore..."
GITIGNORE="$TARGET_PROJECT/.gitignore"

# Entries to add
GITIGNORE_ENTRIES=(
    ".harness/memory/local/"
    ".harness/packs/"
)

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
echo ""
echo "  Installed components:"
echo "    .harness/agents/       — $(ls "$HARNESS_TARGET/agents/"*.md 2>/dev/null | wc -l | xargs) agents"
echo "    .harness/skills/       — $(ls -d "$HARNESS_TARGET/skills/"*/ 2>/dev/null | wc -l | xargs) skills"
echo "    .harness/hooks/        — $(ls "$HARNESS_TARGET/hooks/"*.md 2>/dev/null | wc -l | xargs) hooks"
echo "    .harness/memory/       — shared + local directories"
echo "    .claude/               — Claude Code adapter"
echo "    opencode.json          — OpenCode adapter"
if $ENABLE_CURSOR; then
echo "    .cursor/               — Cursor adapter"
fi
if $ENABLE_CODEX; then
echo "    .agents/               — Codex CLI adapter"
fi
echo ""
echo "  Next steps:"
echo "    1. Fill in .harness/project-context.md"
echo "    2. Run ./scripts/doctor.sh $TARGET_PROJECT"
echo "    3. Open the project with your AI agent"
echo ""
