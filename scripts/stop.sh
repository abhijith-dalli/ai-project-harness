#!/usr/bin/env bash
set -euo pipefail

# AI Project Harness — Stop agentmemory service
# Usage: ./stop.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PID_FILE="/tmp/agentmemory.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping agentmemory (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo -e "${GREEN}agentmemory stopped${NC}"
    else
        echo -e "${YELLOW}agentmemory process not running (stale PID file)${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo -e "${YELLOW}No agentmemory PID file found${NC}"
fi

# Also check if it's running on the default port
if curl -fsS http://localhost:3111/agentmemory/health &>/dev/null 2>&1; then
    echo -e "${YELLOW}agentmemory may still be running on port 3111${NC}"
    echo "You may need to stop it manually or kill the process on port 3111"
fi
