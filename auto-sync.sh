#!/bin/bash
# ============================================================
#  FORGE Auto-Sync Watcher
#  Polls the remote git repository for changes to skills or 
#  agents, pulls them, updates the OpenClaw workspace, and 
#  restarts the gateway automatically.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
POLL_INTERVAL=30 # Check every 30 seconds

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

echo "🔄 Starting Auto-Sync Watcher (checking every ${POLL_INTERVAL}s)"
echo "   Press Ctrl+C to stop this watcher."
echo "   Make sure your 'start.sh' is running in a SEPARATE terminal window,"
echo "   or run this script, and it will restart the gateway for you."
echo ""

cd "$SCRIPT_DIR" || exit 1

# Make sure we're actually in a git repo
if [ ! -d ".git" ]; then
    echo "❌ Error: This folder is not a git repository."
    exit 1
fi

merge_agent() {
    local soul_file="$1"
    local role_file="$2"
    local output_file="$3"
    cat "$soul_file" > "$output_file"
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
    cat "$role_file" >> "$output_file"
}

apply_updates() {
    echo "📦 Applying updated skills and prompts to workspace..."
    
    # 1. Update skills
    cp -r "$SCRIPT_DIR/skills/"* "$WORKSPACE_DIR/skills/"
    
    # 2. Re-merge agent prompts
    merge_agent "$SCRIPT_DIR/agents/pm-soul.md"        "$SCRIPT_DIR/agents/pm.md"        "$WORKSPACE_DIR/agents/pm-agent.md"
    merge_agent "$SCRIPT_DIR/agents/architect-soul.md" "$SCRIPT_DIR/agents/architect.md" "$WORKSPACE_DIR/agents/architect-agent.md"
    merge_agent "$SCRIPT_DIR/agents/developer-soul.md" "$SCRIPT_DIR/agents/developer.md" "$WORKSPACE_DIR/agents/developer-agent.md"
    merge_agent "$SCRIPT_DIR/agents/tester-soul.md"    "$SCRIPT_DIR/agents/tester.md"    "$WORKSPACE_DIR/agents/tester-agent.md"
    
    cp "$SCRIPT_DIR/SOUL.md"   "$WORKSPACE_DIR/SOUL.md"
    cp "$SCRIPT_DIR/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
    
    echo "🔄 Automatically restarting the OpenClaw gateway..."
    
    # Run stop script
    "$SCRIPT_DIR/stop.sh"
    
    # Restart the process using start.sh in the background
    # using nohup so it doesn't die if this terminal is closed
    echo "🚀 Starting new gateway process..."
    nohup "$SCRIPT_DIR/start.sh" > "$SCRIPT_DIR/gateway.log" 2>&1 &
    
    echo "✅ Gateway restarted successfully with new instructions."
}

# Ensure gateway is running to start with
if ! pgrep -f "openclaw" > /dev/null; then
    echo "▶️  Gateway not running. Starting it now..."
    nohup "$SCRIPT_DIR/start.sh" > "$SCRIPT_DIR/gateway.log" 2>&1 &
fi

git fetch origin --quiet

while true; do
    git fetch origin --quiet
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ -z "$REMOTE" ]; then
        # No upstream branch
        sleep "$POLL_INTERVAL"
        continue
    fi
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo ""
        echo "=================================================="
        echo "🔔 Remote changes detected at $(date)!"
        echo "=================================================="
        
        # Pull the changes
        git pull --quiet
        
        # Apply the changes to workspace and restart the gateway
        apply_updates
    fi
    
    sleep "$POLL_INTERVAL"
done
