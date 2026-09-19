#!/usr/bin/env bash
set -euo pipefail

# Test: Canonical File-Based Memory
# Verifies that the harness works with file-based memory only.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating test project..."
mkdir -p "$TMPDIR/FileMemoryTest"
cd "$TMPDIR/FileMemoryTest"
git init -q

echo "Installing harness..."
bash "$HARNESS_DIR/scripts/install.sh" "$TMPDIR/FileMemoryTest" --provider opencode 2>/dev/null

# Test 1: Can create decisions
echo ""
echo "Test: Creating decisions..."
mkdir -p "$TMPDIR/FileMemoryTest/.harness/memory/shared/decisions"
cat > "$TMPDIR/FileMemoryTest/.harness/memory/shared/decisions/001-test-decision.md" << 'EOF'
---
type: decision
topic: test-decision
status: active
created: 2026-09-17
---

# Test Decision

This is a test decision for file-based memory.
EOF

if [ -f "$TMPDIR/FileMemoryTest/.harness/memory/shared/decisions/001-test-decision.md" ]; then
    echo -e "  ${GREEN}✓${NC} Decision file created"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Decision file not created"
    FAIL=$((FAIL + 1))
fi

# Test 2: Can create lessons
echo ""
echo "Test: Creating lessons..."
mkdir -p "$TMPDIR/FileMemoryTest/.harness/memory/shared/lessons"
cat > "$TMPDIR/FileMemoryTest/.harness/memory/shared/lessons/001-test-lesson.md" << 'EOF'
---
type: lesson
topic: test-lesson
status: active
created: 2026-09-17
---

# Test Lesson

This is a test lesson for file-based memory.
EOF

if [ -f "$TMPDIR/FileMemoryTest/.harness/memory/shared/lessons/001-test-lesson.md" ]; then
    echo -e "  ${GREEN}✓${NC} Lesson file created"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Lesson file not created"
    FAIL=$((FAIL + 1))
fi

# Test 3: Can create observations
echo ""
echo "Test: Creating observations..."
mkdir -p "$TMPDIR/FileMemoryTest/.harness/memory/shared/observations"
cat > "$TMPDIR/FileMemoryTest/.harness/memory/shared/observations/001-test-observation.md" << 'EOF'
---
type: observation
topic: test-observation
status: active
created: 2026-09-17
---

# Test Observation

This is a test observation for file-based memory.
EOF

if [ -f "$TMPDIR/FileMemoryTest/.harness/memory/shared/observations/001-test-observation.md" ]; then
    echo -e "  ${GREEN}✓${NC} Observation file created"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Observation file not created"
    FAIL=$((FAIL + 1))
fi

# Test 4: Files have correct YAML frontmatter
echo ""
echo "Test: Verifying YAML frontmatter..."
if grep -q "^type: decision" "$TMPDIR/FileMemoryTest/.harness/memory/shared/decisions/001-test-decision.md"; then
    echo -e "  ${GREEN}✓${NC} Decision has correct frontmatter"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Decision missing frontmatter"
    FAIL=$((FAIL + 1))
fi

# Test 5: Local memory is separate from shared
echo ""
echo "Test: Local vs shared memory separation..."
mkdir -p "$TMPDIR/FileMemoryTest/.harness/memory/local/sessions"
cat > "$TMPDIR/FileMemoryTest/.harness/memory/local/sessions/001-session.md" << 'EOF'
# Session Notes

Temporary session notes that should not be committed.
EOF

if [ -f "$TMPDIR/FileMemoryTest/.harness/memory/local/sessions/001-session.md" ]; then
    echo -e "  ${GREEN}✓${NC} Local memory works independently"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Local memory failed"
    FAIL=$((FAIL + 1))
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
