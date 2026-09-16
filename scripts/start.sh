#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness — Start agentmemory service
# Only required when agentmemory integration is enabled.
# Usage: ./start.sh /path/to/project

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_PROJECT="${1:-}"

if [ -z "$TARGET_PROJECT" ]; then
    echo "Usage: $0 <target-project-path>"
    exit 1
fi

TARGET_PROJECT="$(cd "$TARGET_PROJECT" 2>/dev/null && pwd)" || {
    echo -e "${RED}Target project does not exist: $TARGET_PROJECT${NC}"
    exit 1
}

# Check if agentmemory is already running
if curl -fsS http://localhost:3111/agentmemory/health &>/dev/null 2>&1; then
    echo -e "${GREEN}agentmemory is already running${NC}"
    exit 0
fi

echo -e "${BLUE}Starting agentmemory service...${NC}"

# Check for Node.js
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js is required for agentmemory${NC}"
    echo "Install Node.js >= 20.0.0"
    exit 1
fi

# Start agentmemory in background
if command -v npx &>/dev/null; then
    echo "Using npx to start agentmemory..."
    nohup npx -y @agentmemory/agentmemory@latest > /tmp/agentmemory.log 2>&1 &
    AGENTMEMORY_PID=$!
    echo "$AGENTMEMORY_PID" > /tmp/agentmemory.pid

    # Wait for service to be ready
    echo "Waiting for service to start..."
    for i in $(seq 1 30); do
        if curl -fsS http://localhost:3111/agentmemory/health &>/dev/null 2>&1; then
            echo -e "${GREEN}agentmemory started successfully (PID: $AGENTMEMORY_PID)${NC}"
            echo -e "  Health: http://localhost:3111/agentmemory/health"
            echo -e "  Logs:   /tmp/agentmemory.log"
            exit 0
        fi
        sleep 1
    done

    echo -e "${YELLOW}agentmemory started but health check timed out${NC}"
    echo "Check logs: /tmp/agentmemory.log"
    exit 0
else
    echo -e "${RED}npx is required to start agentmemory${NC}"
    echo "Install npm/npx"
    exit 1
fi
