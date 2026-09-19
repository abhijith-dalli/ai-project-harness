#!/usr/bin/env bash
set -euo pipefail

# Test: Installation Verification
# Creates a temporary project, installs the harness, and verifies all expected files exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

assert_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $file — MISSING"
        FAIL=$((FAIL + 1))
    fi
}

assert_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir/"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $dir/ — MISSING"
        FAIL=$((FAIL + 1))
    fi
}

# Create temporary project
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating temporary project at $TMPDIR"
mkdir -p "$TMPDIR/TestProject"
cd "$TMPDIR/TestProject"
git init -q

echo ""
echo "Installing harness..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/TestProject" --provider opencode 2>/dev/null

echo ""
echo "Verifying installation..."

# Core harness structure
echo ""
echo "Core harness structure:"
assert_dir "$TMPDIR/TestProject/.harness"
assert_dir "$TMPDIR/TestProject/.harness/agents"
assert_dir "$TMPDIR/TestProject/.harness/skills"
assert_dir "$TMPDIR/TestProject/.harness/hooks"
assert_dir "$TMPDIR/TestProject/.harness/config"
assert_dir "$TMPDIR/TestProject/.harness/memory/shared"
assert_dir "$TMPDIR/TestProject/.harness/memory/local"

# Agents
echo ""
echo "Agents:"
for agent in orchestrator explorer researcher planner implementer reviewer debugger; do
    assert_file "$TMPDIR/TestProject/.harness/agents/$agent.md"
done

# Skills (core 8)
echo ""
echo "Skills (core):"
for skill in brainstorming codebase-exploration context-management executing-plans memory-discipline memory-recall memory-save planning; do
    assert_file "$TMPDIR/TestProject/.harness/skills/$skill/SKILL.md"
done

# Skills (additional 9)
echo ""
echo "Skills (additional):"
for skill in dispatching-parallel-agents git-workflow receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development testing verifying-before-completion; do
    assert_file "$TMPDIR/TestProject/.harness/skills/$skill/SKILL.md"
done

# Hooks
echo ""
echo "Hooks:"
for hook in session-start.md before-task.md after-task.md before-commit.md; do
    assert_file "$TMPDIR/TestProject/.harness/hooks/$hook"
done

# Config
echo ""
echo "Config:"
assert_file "$TMPDIR/TestProject/.harness/config/harness.yaml"
assert_file "$TMPDIR/TestProject/.harness/project-context.md"

# Provider adapter (OpenCode)
echo ""
echo "Provider adapter (OpenCode):"
assert_file "$TMPDIR/TestProject/.opencode/AGENTS.md"
assert_file "$TMPDIR/TestProject/opencode.json"
assert_file "$TMPDIR/TestProject/.opencode/plugins/harness-hooks.js"
assert_file "$TMPDIR/TestProject/.harness/manifest.json"

# Memory READMEs
echo ""
echo "Memory READMEs:"
assert_file "$TMPDIR/TestProject/.harness/memory/shared/README.md"
assert_file "$TMPDIR/TestProject/.harness/memory/local/README.md"
assert_file "$TMPDIR/TestProject/.harness/memory/shared/decisions/README.md"
assert_file "$TMPDIR/TestProject/.harness/memory/shared/lessons/README.md"
assert_file "$TMPDIR/TestProject/.harness/memory/shared/observations/README.md"
assert_file "$TMPDIR/TestProject/.harness/memory/shared/project/README.md"

# .gitignore
echo ""
echo "Gitignore:"
assert_file "$TMPDIR/TestProject/.gitignore"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Passed: $PASS  Failed: $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}TEST FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}TEST PASSED${NC}"
    exit 0
fi
