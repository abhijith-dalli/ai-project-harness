#!/usr/bin/env bash
set -euo pipefail

# Test: Reinstall Safety
# Installs twice and verifies no corruption.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# Create temporary project
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating test project..."
mkdir -p "$TMPDIR/ReinstallTest"
cd "$TMPDIR/ReinstallTest"
git init -q

# First install
echo ""
echo "First install..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/ReinstallTest" 2>/dev/null

# Count files after first install
FIRST_AGENT_COUNT=$(ls "$TMPDIR/ReinstallTest/.harness/agents/"*.md 2>/dev/null | wc -l | xargs)
FIRST_SKILL_COUNT=$(ls -d "$TMPDIR/ReinstallTest/.harness/skills/"*/ 2>/dev/null | wc -l | xargs)

echo "  Agents: $FIRST_AGENT_COUNT, Skills: $FIRST_SKILL_COUNT"

# Create custom memory
echo ""
echo "Creating custom memory..."
mkdir -p "$TMPDIR/ReinstallTest/.harness/memory/shared/decisions"
cat > "$TMPDIR/ReinstallTest/.harness/memory/shared/decisions/001-custom.md" << 'EOF'
---
type: decision
topic: custom-decision
status: active
created: 2026-09-17
---

# Custom Decision

This should survive reinstallation.
EOF

# Create custom project context
echo "Custom project context" > "$TMPDIR/ReinstallTest/.harness/project-context.md"

# Second install
echo ""
echo "Second install..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/ReinstallTest" 2>/dev/null

# Count files after second install
SECOND_AGENT_COUNT=$(ls "$TMPDIR/ReinstallTest/.harness/agents/"*.md 2>/dev/null | wc -l | xargs)
SECOND_SKILL_COUNT=$(ls -d "$TMPDIR/ReinstallTest/.harness/skills/"*/ 2>/dev/null | wc -l | xargs)

echo "  Agents: $SECOND_AGENT_COUNT, Skills: $SECOND_SKILL_COUNT"

# Verify same file counts
echo ""
echo "Verifying no corruption..."

if [ "$FIRST_AGENT_COUNT" -eq "$SECOND_AGENT_COUNT" ]; then
    echo -e "  ${GREEN}✓${NC} Agent count unchanged ($SECOND_AGENT_COUNT)"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Agent count changed ($FIRST_AGENT_COUNT → $SECOND_AGENT_COUNT)"
    ((FAIL++))
fi

if [ "$FIRST_SKILL_COUNT" -eq "$SECOND_SKILL_COUNT" ]; then
    echo -e "  ${GREEN}✓${NC} Skill count unchanged ($SECOND_SKILL_COUNT)"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Skill count changed ($FIRST_SKILL_COUNT → $SECOND_SKILL_COUNT)"
    ((FAIL++))
fi

# Verify custom data survived
echo ""
echo "Verifying custom data preserved..."

if [ -f "$TMPDIR/ReinstallTest/.harness/memory/shared/decisions/001-custom.md" ]; then
    echo -e "  ${GREEN}✓${NC} Custom memory survived reinstallation"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Custom memory lost after reinstallation"
    ((FAIL++))
fi

if grep -q "Custom project context" "$TMPDIR/ReinstallTest/.harness/project-context.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Custom project context preserved"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Custom project context lost"
    ((FAIL++))
fi

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
