#!/usr/bin/env bash
set -euo pipefail

# Provider Installation Test
# Tests that each provider can be installed exclusively.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }

test_provider() {
    local provider="$1"
    local test_name="$provider provider"

    echo ""
    echo "Testing $test_name..."

    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir/TestProject"
    cd "$test_dir/TestProject"
    git init 2>/dev/null

    # Install with provider flag
    if bash "$HARNESS_DIR/scripts/install.sh" . --provider "$provider" >/dev/null 2>&1; then
        pass "$test_name: installation succeeded"
    else
        fail "$test_name: installation failed"
        rm -rf "$test_dir"
        return
    fi

    # Verify manifest
    if [ -f ".harness/manifest.json" ]; then
        manifest_provider=$(grep -o '"provider": *"[^"]*"' .harness/manifest.json | cut -d'"' -f4)
        if [ "$manifest_provider" = "$provider" ]; then
            pass "$test_name: manifest has correct provider"
        else
            fail "$test_name: manifest has wrong provider (got $manifest_provider)"
        fi
    else
        fail "$test_name: manifest.json not created"
    fi

    # Verify provider-specific structure
    case $provider in
        opencode)
            [ -d ".opencode" ] && pass "$test_name: .opencode/ exists" || fail "$test_name: .opencode/ missing"
            [ -f ".opencode/AGENTS.md" ] && pass "$test_name: AGENTS.md exists" || fail "$test_name: AGENTS.md missing"
            skill_count=$(ls -d ".opencode/skills/"*/ 2>/dev/null | wc -l | xargs)
            [ "$skill_count" -eq 17 ] && pass "$test_name: 17 skills" || fail "$test_name: expected 17 skills, got $skill_count"
            agent_count=$(ls ".opencode/agents/"*.md 2>/dev/null | wc -l | xargs)
            [ "$agent_count" -eq 7 ] && pass "$test_name: 7 agents" || fail "$test_name: expected 7 agents, got $agent_count"
            [ -f ".opencode/plugins/harness-hooks.js" ] && pass "$test_name: plugin exists" || fail "$test_name: plugin missing"
            [ ! -d ".claude" ] && pass "$test_name: no .claude/ (exclusive)" || fail "$test_name: .claude/ should not exist"
            [ ! -d ".cursor" ] && pass "$test_name: no .cursor/ (exclusive)" || fail "$test_name: .cursor/ should not exist"
            [ ! -d ".codex" ] && pass "$test_name: no .codex/ (exclusive)" || fail "$test_name: .codex/ should not exist"
            ;;
        claude)
            [ -d ".claude" ] && pass "$test_name: .claude/ exists" || fail "$test_name: .claude/ missing"
            [ -f ".claude/CLAUDE.md" ] && pass "$test_name: CLAUDE.md exists" || fail "$test_name: CLAUDE.md missing"
            [ -f ".claude/hooks.json" ] && pass "$test_name: hooks.json exists" || fail "$test_name: hooks.json missing"
            skill_count=$(ls -d ".claude/skills/"*/ 2>/dev/null | wc -l | xargs)
            [ "$skill_count" -eq 17 ] && pass "$test_name: 17 skills" || fail "$test_name: expected 17 skills, got $skill_count"
            agent_count=$(ls ".claude/agents/"*.md 2>/dev/null | wc -l | xargs)
            [ "$agent_count" -eq 7 ] && pass "$test_name: 7 agents" || fail "$test_name: expected 7 agents, got $agent_count"
            hook_count=$(ls ".claude/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            [ "$hook_count" -eq 6 ] && pass "$test_name: 6 hooks" || fail "$test_name: expected 6 hooks, got $hook_count"
            [ ! -d ".opencode" ] && pass "$test_name: no .opencode/ (exclusive)" || fail "$test_name: .opencode/ should not exist"
            ;;
        cursor)
            [ -d ".cursor" ] && pass "$test_name: .cursor/ exists" || fail "$test_name: .cursor/ missing"
            [ -f ".cursor/.cursorrules" ] && pass "$test_name: .cursorrules exists" || fail "$test_name: .cursorrules missing"
            [ -f ".cursor/hooks.json" ] && pass "$test_name: hooks.json exists" || fail "$test_name: hooks.json missing"
            hook_count=$(ls ".cursor/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            [ "$hook_count" -eq 6 ] && pass "$test_name: 6 hooks" || fail "$test_name: expected 6 hooks, got $hook_count"
            [ ! -d ".opencode" ] && pass "$test_name: no .opencode/ (exclusive)" || fail "$test_name: .opencode/ should not exist"
            [ ! -d ".claude" ] && pass "$test_name: no .claude/ (exclusive)" || fail "$test_name: .claude/ should not exist"
            ;;
        codex)
            [ -d ".codex" ] && pass "$test_name: .codex/ exists" || fail "$test_name: .codex/ missing"
            [ -f "AGENTS.md" ] && pass "$test_name: AGENTS.md exists" || fail "$test_name: AGENTS.md missing"
            [ -f ".codex/hooks.json" ] && pass "$test_name: hooks.json exists" || fail "$test_name: hooks.json missing"
            agent_count=$(ls ".codex/agents/"*.toml 2>/dev/null | wc -l | xargs)
            [ "$agent_count" -eq 7 ] && pass "$test_name: 7 agents" || fail "$test_name: expected 7 agents, got $agent_count"
            hook_count=$(ls ".codex/hooks/"*.sh 2>/dev/null | wc -l | xargs)
            [ "$hook_count" -eq 4 ] && pass "$test_name: 4 hooks" || fail "$test_name: expected 4 hooks, got $hook_count"
            [ ! -d ".opencode" ] && pass "$test_name: no .opencode/ (exclusive)" || fail "$test_name: .opencode/ should not exist"
            [ ! -d ".claude" ] && pass "$test_name: no .claude/ (exclusive)" || fail "$test_name: .claude/ should not exist"
            ;;
    esac

    # Verify harness core is intact
    [ -d ".harness/agents" ] && pass "$test_name: harness agents" || fail "$test_name: harness agents missing"
    [ -d ".harness/skills" ] && pass "$test_name: harness skills" || fail "$test_name: harness skills missing"
    [ -d ".harness/dashboard" ] && pass "$test_name: harness dashboard" || fail "$test_name: harness dashboard missing"
    [ -d ".harness/memory" ] && pass "$test_name: harness memory" || fail "$test_name: harness memory missing"

    rm -rf "$test_dir"
}

# Run tests for all providers
for provider in opencode claude cursor codex; do
    test_provider "$provider"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passed: $PASS  Failed: $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
