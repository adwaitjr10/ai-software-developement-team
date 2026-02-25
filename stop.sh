#!/bin/bash
# Stop the FORGE gateway
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 2>/dev/null
echo "🛑 Stopping FORGE gateway..."
openclaw gateway stop 2>/dev/null || pkill -f "openclaw-gateway" 2>/dev/null || true
echo "✅ Gateway stopped."
