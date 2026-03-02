#!/bin/bash
# Start the FORGE gateway
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load NVM
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
else
    echo -e "${RED}✗ NVM not found. Install Node.js via nvm first:${NC}"
    echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    exit 1
fi

# Switch to Node 22
if ! nvm use 22 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Node 22 not installed. Installing...${NC}"
    nvm install 22
    nvm use 22
fi

# Verify OpenClaw is installed
if ! command -v openclaw &>/dev/null; then
    echo -e "${RED}✗ OpenClaw not found. Install it first:${NC}"
    echo "  npm install -g openclaw@latest"
    echo "  openclaw onboard"
    exit 1
fi

# Check if gateway is already running
GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
if [ -n "$GATEWAY_PID" ]; then
    echo -e "${YELLOW}⚠️  Gateway already running (PID: $GATEWAY_PID)${NC}"
    echo ""
    read -r -p "Stop and restart? [Y/n]: " RESTART_CHOICE
    if [[ ! "$RESTART_CHOICE" =~ ^[Nn]$ ]]; then
        echo "Stopping existing gateway..."
        kill "$GATEWAY_PID" 2>/dev/null || true
        sleep 2
        # Force kill if still running
        GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
        if [ -n "$GATEWAY_PID" ]; then
            kill -9 "$GATEWAY_PID" 2>/dev/null || true
            sleep 1
        fi
    else
        echo "Exiting. Gateway left running."
        exit 0
    fi
fi

# Load environment credentials
if [ -f "$HOME/.forge-env" ]; then
    source "$HOME/.forge-env"
    echo -e "${GREEN}✓${NC} Environment credentials loaded"
elif [ -f "$HOME/.aws-bedrock-creds" ]; then
    source "$HOME/.aws-bedrock-creds"
    echo -e "${GREEN}✓${NC} AWS Bedrock credentials loaded"
else
    echo -e "${YELLOW}⚠️  No environment credentials found (not required for all setups)${NC}"
fi

# Verify config exists
if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    echo -e "${RED}✗ OpenClaw config not found. Run ./setup.sh first${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🦞  Starting FORGE Virtual Team Gateway${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Bot endpoints will be available after startup:"
echo "  • Message your FORGE bot on Telegram to start"
echo "  • Use /status to check pipeline status"
echo "  • Press Ctrl+C to stop"
echo ""

# Start gateway with error handling
if openclaw gateway; then
    # Gateway exited normally
    echo ""
    echo -e "${GREEN}✓ Gateway stopped cleanly${NC}"
else
    # Gateway exited with error
    EXIT_CODE=$?
    echo ""
    if [ $EXIT_CODE -ne 0 ]; then
        echo -e "${RED}✗ Gateway exited with error (code: $EXIT_CODE)${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check logs: tail -f ~/.openclaw/logs/gateway.log"
        echo "  2. Verify config: cat ~/.openclaw/openclaw.json | jq ."
        echo "  3. Test bot tokens: curl https://api.telegram.org/bot<TOKEN>/getMe"
        echo "  4. Check port 18789: lsof -i:18789"
        exit $EXIT_CODE
    fi
fi
