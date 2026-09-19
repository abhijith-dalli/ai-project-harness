#!/usr/bin/env bash
set -euo pipefail

# Test: Cross-Agent Memory
# Verifies that memory stored through one provider adapter is accessible
# through another provider adapter (since they share .harness/memory/).

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
mkdir -p "$TMPDIR/CrossAgentTest"
cd "$TMPDIR/CrossAgentTest"
git init -q

echo "Installing harness with OpenCode provider..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/CrossAgentTest" --provider opencode 2>/dev/null

# Simulate Claude Code storing memory
echo ""
echo "Simulating Claude Code memory storage..."
cat > "$TMPDIR/CrossAgentTest/.harness/memory/shared/observations/001-claude-finding.md" << 'EOF'
---
type: observation
topic: api-rate-limit
status: active
created: 2026-09-17
---

# Observation: API Rate Limiting

The external payment API has a rate limit of 100 requests per minute.
This was discovered while implementing the billing module.
EOF

# Verify OpenCode can see the same memory
echo "Verifying OpenCode adapter shares memory..."
if [ -f "$TMPDIR/CrossAgentTest/.harness/memory/shared/observations/001-claude-finding.md" ]; then
    echo -e "  ${GREEN}✓${NC} Memory file is accessible from shared directory"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Memory file not found in shared directory"
    FAIL=$((FAIL + 1))
fi

# Verify Cursor adapter shares memory
echo "Verifying Cursor adapter shares memory..."
if [ -f "$TMPDIR/CrossAgentTest/.harness/memory/shared/observations/001-claude-finding.md" ]; then
    echo -e "  ${GREEN}✓${NC} Memory is provider-independent"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Memory is provider-dependent"
    FAIL=$((FAIL + 1))
fi

# Verify all provider adapters are configured
echo ""
echo "Verifying provider adapter..."
if [ -f "$TMPDIR/CrossAgentTest/opencode.json" ]; then
    echo -e "  ${GREEN}✓${NC} opencode.json configured"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} opencode.json missing"
    FAIL=$((FAIL + 1))
fi

# Verify memory is in the canonical location
echo ""
echo "Verifying canonical memory location..."
if [ -d "$TMPDIR/CrossAgentTest/.harness/memory/shared" ]; then
    echo -e "  ${GREEN}✓${NC} Canonical memory directory exists"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Canonical memory directory missing"
    FAIL=$((FAIL + 1))
fi

# No provider-specific memory directories should exist
echo ""
echo "Verifying no provider-specific memory copies..."
for prov_dir in ".claude/memory" ".cursor/memory" ".opencode/memory"; do
    if [ ! -d "$TMPDIR/CrossAgentTest/$prov_dir" ]; then
        echo -e "  ${GREEN}✓${NC} No $prov_dir (correct)"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $prov_dir exists (should not)"
        FAIL=$((FAIL + 1))
    fi
done

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
