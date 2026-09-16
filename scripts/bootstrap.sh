#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness — Bootstrap
# Quick setup: install + doctor + verify memory
# Usage: ./bootstrap.sh /path/to/project [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_PROJECT="${1:-}"
shift || true

if [ -z "$TARGET_PROJECT" ]; then
    echo "Usage: $0 <target-project-path> [--enable-agentmemory] [--packs backend,database]"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  AI Project Harness — Bootstrap${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Install
echo -e "${BLUE}Step 1: Installing harness...${NC}"
bash "$SCRIPT_DIR/install.sh" "$TARGET_PROJECT" "$@"
echo ""

# Step 2: Doctor
echo -e "${BLUE}Step 2: Running diagnostics...${NC}"
bash "$SCRIPT_DIR/doctor.sh" "$TARGET_PROJECT"
echo ""

# Step 3: Verify memory
echo -e "${BLUE}Step 3: Verifying memory architecture...${NC}"
HARNESS_TARGET="$TARGET_PROJECT/.harness"

if [ -d "$HARNESS_TARGET/memory/shared" ] && [ -d "$HARNESS_TARGET/memory/local" ]; then
    echo -e "${GREEN}  Memory architecture: OK${NC}"
    echo -e "    shared/ — durable project knowledge"
    echo -e "    local/  — temporary session context"
else
    echo -e "${RED}  Memory architecture: INCOMPLETE${NC}"
fi

echo ""

# Step 4: Status
echo -e "${BLUE}Step 4: Final status...${NC}"
bash "$SCRIPT_DIR/status.sh" "$TARGET_PROJECT"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Bootstrap complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  The harness is installed and ready."
echo "  Open the project with your AI agent to start using it."
echo ""
