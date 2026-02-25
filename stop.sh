#!/bin/bash
# Stop the FORGE gateway
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 2>/dev/null
echo "🛑 Stopping FORGE gateway..."

# Try openclaw stop first
openclaw gateway stop 2>/dev/null

# Force kill any remaining gateway process
GATEWAY_PID=$(lsof -ti:18789 2>/dev/null)
if [ -n "$GATEWAY_PID" ]; then
    kill "$GATEWAY_PID" 2>/dev/null
    sleep 1
    # Force kill if still running
    kill -9 "$GATEWAY_PID" 2>/dev/null || true
fi

echo "✅ Gateway stopped."
