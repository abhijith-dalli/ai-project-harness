#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness Doctor
# Verifies the harness installation and reports status.
# Usage: ./doctor.sh /path/to/project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local status="$1"
    local message="$2"
    case $status in
        ok)   echo -e "  ${GREEN}✓${NC} $message"; PASS=$((PASS + 1)) ;;
        warn) echo -e "  ${YELLOW}⚠${NC} $message"; WARN=$((WARN + 1)) ;;
        fail) echo -e "  ${RED}✗${NC} $message"; FAIL=$((FAIL + 1)) ;;
    esac
}

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

echo ""
echo -e "${BLUE}AI Project Harness — Doctor${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Project: $TARGET_PROJECT"
echo ""

# ─── 1. Harness installation ─────────────────────────────────────

echo -e "${BLUE}Harness Installation${NC}"

if [ -d "$HARNESS_TARGET" ]; then
    check ok ".harness/ directory exists"
else
    check fail ".harness/ directory not found — run install.sh"
    echo ""
    echo -e "${RED}Cannot continue without .harness/ directory${NC}"
    exit 1
fi

agent_count=$(ls "$HARNESS_TARGET/agents/"*.md 2>/dev/null | wc -l | xargs)
if [ "$agent_count" -gt 0 ]; then
    check ok "Agents: $agent_count installed"
else
    check fail "No agents found"
fi

skill_count=$(ls -d "$HARNESS_TARGET/skills/"*/ 2>/dev/null | wc -l | xargs)
if [ "$skill_count" -gt 0 ]; then
    check ok "Skills: $skill_count installed"
else
    check fail "No skills found"
fi

hook_count=$(ls "$HARNESS_TARGET/hooks/"*.md 2>/dev/null | wc -l | xargs)
if [ "$hook_count" -gt 0 ]; then
    check ok "Hooks: $hook_count installed"
else
    check warn "No hooks found"
fi

if [ -f "$HARNESS_TARGET/config/harness.yaml" ]; then
    check ok "Configuration: harness.yaml exists"
else
    check warn "No harness.yaml configuration"
fi

if [ -f "$HARNESS_TARGET/project-context.md" ]; then
    check ok "Project context: exists"
    if grep -q "Name:$" "$HARNESS_TARGET/project-context.md" 2>/dev/null; then
        check warn "Project context: not filled in yet"
    else
        check ok "Project context: filled in"
    fi
else
    check warn "No project-context.md"
fi

echo ""

# ─── 2. Memory architecture ──────────────────────────────────────

echo -e "${BLUE}Memory Architecture${NC}"

if [ -d "$HARNESS_TARGET/memory/shared" ]; then
    check ok "Shared memory directory exists"
else
    check fail "Shared memory directory missing"
fi

if [ -d "$HARNESS_TARGET/memory/local" ]; then
    check ok "Local memory directory exists"
else
    check warn "Local memory directory missing"
fi

shared_files=$(find "$HARNESS_TARGET/memory/shared" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
if [ "$shared_files" -gt 0 ]; then
    check ok "Shared memory: $shared_files files"
else
    check warn "Shared memory: no files yet"
fi

echo ""

# ─── 3. Provider adapters ────────────────────────────────────────

echo -e "${BLUE}Provider Adapters${NC}"

# Read provider from manifest
PROVIDER=""
if [ -f "$HARNESS_TARGET/manifest.json" ]; then
    PROVIDER=$(grep -o '"provider": *"[^"]*"' "$HARNESS_TARGET/manifest.json" | cut -d'"' -f4)
    check ok "Provider manifest: $PROVIDER"
else
    check warn "No provider manifest found"
fi

# Check provider-specific directories
case $PROVIDER in
    opencode)
        if [ -f "$TARGET_PROJECT/.opencode/AGENTS.md" ]; then
            check ok "OpenCode: AGENTS.md exists"
        else
            check fail "OpenCode: AGENTS.md missing"
        fi
        if [ -d "$TARGET_PROJECT/.opencode/skills" ]; then
            skill_count=$(ls -d "$TARGET_PROJECT/.opencode/skills/"*/ 2>/dev/null | wc -l | xargs)
            check ok "OpenCode: $skill_count skills installed"
        else
            check fail "OpenCode: skills directory missing"
        fi
        if [ -d "$TARGET_PROJECT/.opencode/agents" ]; then
            agent_count=$(ls "$TARGET_PROJECT/.opencode/agents/"*.md 2>/dev/null | wc -l | xargs)
            check ok "OpenCode: $agent_count agents installed"
        else
            check fail "OpenCode: agents directory missing"
        fi
        if [ -f "$TARGET_PROJECT/.opencode/plugins/harness-hooks.js" ]; then
            check ok "OpenCode: harness-hooks.js plugin exists"
        else
            check fail "OpenCode: harness-hooks.js plugin missing"
        fi
        if [ -f "$TARGET_PROJECT/opencode.json" ]; then
            check ok "OpenCode: opencode.json exists"
        else
            check warn "OpenCode: opencode.json missing"
        fi
        ;;
    claude)
        if [ -f "$TARGET_PROJECT/.claude/CLAUDE.md" ]; then
            check ok "Claude Code: CLAUDE.md exists"
        else
            check fail "Claude Code: CLAUDE.md missing"
        fi
        if [ -f "$TARGET_PROJECT/.claude/settings.json" ]; then
            check ok "Claude Code: settings.json exists"
        else
            check fail "Claude Code: settings.json missing"
        fi
        if [ -f "$TARGET_PROJECT/.claude/hooks.json" ]; then
            check ok "Claude Code: hooks.json exists"
        else
            check fail "Claude Code: hooks.json missing"
        fi
        if [ -d "$TARGET_PROJECT/.claude/skills" ]; then
            skill_count=$(ls -d "$TARGET_PROJECT/.claude/skills/"*/ 2>/dev/null | wc -l | xargs)
            check ok "Claude Code: $skill_count skills installed"
        else
            check fail "Claude Code: skills directory missing"
        fi
        if [ -d "$TARGET_PROJECT/.claude/agents" ]; then
            agent_count=$(ls "$TARGET_PROJECT/.claude/agents/"*.md 2>/dev/null | wc -l | xargs)
            check ok "Claude Code: $agent_count agents installed"
        else
            check fail "Claude Code: agents directory missing"
        fi
        if [ -d "$TARGET_PROJECT/.claude/hooks" ]; then
            hook_count=$(ls "$TARGET_PROJECT/.claude/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            check ok "Claude Code: $hook_count hooks installed"
        else
            check fail "Claude Code: hooks directory missing"
        fi
        ;;
    cursor)
        if [ -f "$TARGET_PROJECT/.cursor/.cursorrules" ]; then
            check ok "Cursor: .cursorrules exists"
        else
            check fail "Cursor: .cursorrules missing"
        fi
        if [ -f "$TARGET_PROJECT/.cursor/rules/harness.md" ]; then
            check ok "Cursor: rules/harness.md exists"
        else
            check fail "Cursor: rules/harness.md missing"
        fi
        if [ -f "$TARGET_PROJECT/.cursor/hooks.json" ]; then
            check ok "Cursor: hooks.json exists"
        else
            check fail "Cursor: hooks.json missing"
        fi
        if [ -d "$TARGET_PROJECT/.cursor/hooks" ]; then
            hook_count=$(ls "$TARGET_PROJECT/.cursor/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            check ok "Cursor: $hook_count hooks installed"
        else
            check fail "Cursor: hooks directory missing"
        fi
        if [ -f "$TARGET_PROJECT/.cursor/mcp.json" ]; then
            check ok "Cursor: mcp.json exists"
        else
            check warn "Cursor: mcp.json missing"
        fi
        ;;
    codex)
        if [ -f "$TARGET_PROJECT/AGENTS.md" ]; then
            check ok "Codex: AGENTS.md exists"
        else
            check fail "Codex: AGENTS.md missing"
        fi
        if [ -d "$TARGET_PROJECT/.codex/agents" ]; then
            agent_count=$(ls "$TARGET_PROJECT/.codex/agents/"*.toml 2>/dev/null | wc -l | xargs)
            check ok "Codex: $agent_count agents installed"
        else
            check fail "Codex: agents directory missing"
        fi
        if [ -d "$TARGET_PROJECT/.codex/hooks" ]; then
            hook_count=$(ls "$TARGET_PROJECT/.codex/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            check ok "Codex: $hook_count hooks installed"
        else
            check fail "Codex: hooks directory missing"
        fi
        if [ -f "$TARGET_PROJECT/.codex/hooks.json" ]; then
            check ok "Codex: hooks.json exists"
        else
            check fail "Codex: hooks.json missing"
        fi
        ;;
    *)
        check warn "Unknown provider: $PROVIDER"
        ;;
esac

echo ""

# ─── 4. Git ──────────────────────────────────────────────────────

echo -e "${BLUE}Git${NC}"

if command -v git &>/dev/null; then
    if git -C "$TARGET_PROJECT" rev-parse --git-dir &>/dev/null; then
        check ok "Git repository detected"

        if grep -qF ".harness/memory/local/" "$TARGET_PROJECT/.gitignore" 2>/dev/null; then
            check ok ".gitignore: local memory is ignored"
        else
            check warn ".gitignore: local memory NOT ignored — add .harness/memory/local/"
        fi
    else
        check warn "Not a Git repository"
    fi
else
    check warn "Git not installed"
fi

echo ""

# ─── Summary ──────────────────────────────────────────────────────

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}  ${YELLOW}Warnings: $WARN${NC}  ${RED}Failed: $FAIL${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some checks failed. Please fix the issues above.${NC}"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}Some warnings. The harness should work, but review the warnings.${NC}"
    exit 0
else
    echo -e "${GREEN}All checks passed! The harness is ready.${NC}"
    exit 0
fi
