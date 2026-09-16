#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness Status
# Shows harness version, installed components, and memory stats.
# Usage: ./status.sh /path/to/project

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

TARGET_PROJECT="${1:-}"

if [ -z "$TARGET_PROJECT" ]; then
    echo "Usage: $0 <target-project-path>"
    exit 1
fi

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    echo -e "${RED}Target project does not exist: $TARGET_PROJECT${NC}"
    exit 1
}

HARNESS_TARGET="$TARGET_PROJECT/.harness"

if [ ! -d "$HARNESS_TARGET" ]; then
    echo -e "${RED}No .harness/ directory found in $TARGET_PROJECT${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}AI Project Harness — Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ─── Harness version ─────────────────────────────────────────────

HARNESS_VERSION="unknown"
if [ -f "$HARNESS_DIR/VERSION" ]; then
    HARNESS_VERSION="$(cat "$HARNESS_DIR/VERSION")"
fi

# Check installed version
INSTALLED_VERSION="unknown"
if [ -f "$HARNESS_TARGET/VERSION" ]; then
    INSTALLED_VERSION="$(cat "$HARNESS_TARGET/VERSION")"
fi

echo -e "  ${BLUE}Harness Version:${NC} $HARNESS_VERSION (template) / $INSTALLED_VERSION (installed)"

# ─── Project info ────────────────────────────────────────────────

PROJECT_NAME="$(basename "$TARGET_PROJECT")"
if git -C "$TARGET_PROJECT" rev-parse --git-dir &>/dev/null 2>&1; then
    GIT_REPO="$(git -C "$TARGET_PROJECT" rev-parse --show-toplevel 2>/dev/null)"
    PROJECT_NAME="$(basename "$GIT_REPO")"
fi

echo -e "  ${BLUE}Project:${NC}         $PROJECT_NAME"
echo -e "  ${BLUE}Location:${NC}        $TARGET_PROJECT"
echo ""

# ─── Components ──────────────────────────────────────────────────

echo -e "${BLUE}Components${NC}"

# Agents
agent_count=$(ls "$HARNESS_TARGET/agents/"*.md 2>/dev/null | wc -l | xargs)
echo -e "  Agents:       $agent_count"

# Skills
skill_count=$(ls -d "$HARNESS_TARGET/skills/"*/ 2>/dev/null | wc -l | xargs)
echo -e "  Skills:       $skill_count"

# Hooks
hook_count=$(ls "$HARNESS_TARGET/hooks/"*.md 2>/dev/null | wc -l | xargs)
echo -e "  Hooks:        $hook_count"

# Packs
if [ -d "$HARNESS_TARGET/packs" ]; then
    pack_count=$(ls -d "$HARNESS_TARGET/packs/"*/ 2>/dev/null | wc -l | xargs)
    echo -e "  Packs:        $pack_count"
else
    echo -e "  Packs:        0"
fi

echo ""

# ─── Memory ──────────────────────────────────────────────────────

echo -e "${BLUE}Memory${NC}"

shared_decisions=$(find "$HARNESS_TARGET/memory/shared/decisions" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
shared_lessons=$(find "$HARNESS_TARGET/memory/shared/lessons" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
shared_observations=$(find "$HARNESS_TARGET/memory/shared/observations" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
shared_project=$(find "$HARNESS_TARGET/memory/shared/project" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
local_sessions=$(find "$HARNESS_TARGET/memory/local/sessions" -name "*.md" 2>/dev/null | wc -l | xargs)

total_shared=$((shared_decisions + shared_lessons + shared_observations + shared_project))

echo -e "  Shared memory:   $total_shared files"
echo -e "    Decisions:     $shared_decisions"
echo -e "    Lessons:       $shared_lessons"
echo -e "    Observations:  $shared_observations"
echo -e "    Project:       $shared_project"
echo -e "  Local sessions:  $local_sessions"
echo ""

# ─── Provider status ─────────────────────────────────────────────

echo -e "${BLUE}Providers${NC}"

[ -f "$TARGET_PROJECT/.claude/settings.json" ] && echo -e "  Claude Code:  ${GREEN}configured${NC}" || echo -e "  Claude Code:  ${YELLOW}not configured${NC}"
[ -f "$TARGET_PROJECT/opencode.json" ] && echo -e "  OpenCode:     ${GREEN}configured${NC}" || echo -e "  OpenCode:     ${YELLOW}not configured${NC}"
[ -f "$TARGET_PROJECT/.cursor/mcp.json" ] && echo -e "  Cursor:       ${GREEN}configured${NC}" || echo -e "  Cursor:       ${YELLOW}not configured${NC}"

echo ""

# ─── agentmemory ─────────────────────────────────────────────────

if curl -fsS http://localhost:3111/agentmemory/health &>/dev/null 2>&1; then
    echo -e "  agentmemory:  ${GREEN}running${NC}"
else
    echo -e "  agentmemory:  ${YELLOW}not running${NC}"
fi

echo ""
