#!/usr/bin/env bash
set -euo pipefail

# Test: Memory Isolation
# Creates two projects, stores memory in one, verifies the other cannot see it.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# Create temporary projects
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating ProjectA and ProjectB..."
mkdir -p "$TMPDIR/ProjectA" "$TMPDIR/ProjectB"
cd "$TMPDIR/ProjectA" && git init -q
cd "$TMPDIR/ProjectB" && git init -q

echo "Installing harness into both..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/ProjectA" 2>/dev/null
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/ProjectB" 2>/dev/null

# Store memory in ProjectA
echo ""
echo "Storing memory in ProjectA..."
cat > "$TMPDIR/ProjectA/.harness/memory/shared/decisions/001-database-choice.md" << 'EOF'
---
type: decision
topic: database-choice
status: active
created: 2026-09-17
---

# Decision: Use PostgreSQL

We chose PostgreSQL for the TaxSystem project because of its strong JSON support
and mature ecosystem.
EOF

# Verify ProjectA has the memory
if [ -f "$TMPDIR/ProjectA/.harness/memory/shared/decisions/001-database-choice.md" ]; then
    echo -e "  ${GREEN}✓${NC} ProjectA has memory file"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} ProjectA missing memory file"
    ((FAIL++))
fi

# Verify ProjectB does NOT have the memory
if [ ! -f "$TMPDIR/ProjectB/.harness/memory/shared/decisions/001-database-choice.md" ]; then
    echo -e "  ${GREEN}✓${NC} ProjectB does NOT have ProjectA's memory"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} ProjectB has ProjectA's memory — ISOLATION FAILURE"
    ((FAIL++))
fi

# Verify memory directories are separate
echo ""
echo "Verifying directory isolation..."

if [ "$TMPDIR/ProjectA/.harness/memory" != "$TMPDIR/ProjectB/.harness/memory" ]; then
    echo -e "  ${GREEN}✓${NC} Memory directories are separate paths"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Memory directories share the same path"
    ((FAIL++))
fi

# Store different memory in ProjectB
cat > "$TMPDIR/ProjectB/.harness/memory/shared/decisions/001-framework-choice.md" << 'EOF'
---
type: decision
topic: framework-choice
status: active
created: 2026-09-17
---

# Decision: Use React

We chose React for the RecruitmentSystem frontend.
EOF

# Verify ProjectA does NOT have ProjectB's memory
if [ ! -f "$TMPDIR/ProjectA/.harness/memory/shared/decisions/001-framework-choice.md" ]; then
    echo -e "  ${GREEN}✓${NC} ProjectA does NOT have ProjectB's memory"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} ProjectA has ProjectB's memory — ISOLATION FAILURE"
    ((FAIL++))
fi

# Verify each project has its own memory
if [ -f "$TMPDIR/ProjectA/.harness/memory/shared/decisions/001-database-choice.md" ] && \
   [ -f "$TMPDIR/ProjectB/.harness/memory/shared/decisions/001-framework-choice.md" ]; then
    echo -e "  ${GREEN}✓${NC} Each project has its own memory"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Memory files missing after cross-store"
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
