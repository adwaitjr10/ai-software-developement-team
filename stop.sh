#!/bin/bash
# Stop the FORGE gateway
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load NVM for openclaw command
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use 22 2>/dev/null || true
fi

echo -e "${YELLOW}🛑 Stopping FORGE gateway...${NC}"

# Method 1: Try OpenClaw's built-in stop command
if command -v openclaw &>/dev/null; then
    if openclaw gateway stop 2>/dev/null; then
        echo -e "${GREEN}✓ Gateway stopped via OpenClaw${NC}"
        sleep 1
    fi
fi

# Method 2: Check and kill process on port 18789
GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
if [ -n "$GATEWAY_PID" ]; then
    echo "Found gateway process (PID: $GATEWAY_PID)"

    # Try graceful shutdown first
    if kill "$GATEWAY_PID" 2>/dev/null; then
        echo "Sent SIGTERM... waiting for graceful shutdown..."
        sleep 2

        # Check if still running
        GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
        if [ -n "$GATEWAY_PID" ]; then
            echo -e "${YELLOW}⚠️  Process still running, forcing shutdown...${NC}"
            kill -9 "$GATEWAY_PID" 2>/dev/null || true
            sleep 1
        fi
    fi

    # Final check
    GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
    if [ -n "$GATEWAY_PID" ]; then
        echo -e "${RED}✗ Failed to stop gateway (PID: $GATEWAY_PID still running)${NC}"
        echo "  Try manually: kill -9 $GATEWAY_PID"
        exit 1
    else
        echo -e "${GREEN}✓ Gateway stopped${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No gateway process found on port 18789${NC}"
    echo "  (May not have been running)"
fi

exit 0
