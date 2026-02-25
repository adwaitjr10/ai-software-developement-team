#!/bin/bash
# ============================================================
#  FORGE Virtual Team — OpenClaw Setup Script
#  Run this ONCE to install the 4-agent software team
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║   FORGE Virtual Team — Setup Installer   ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Verify OpenClaw is installed ────────────────────────────
echo -e "${YELLOW}▶ Checking OpenClaw installation...${NC}"
if ! command -v openclaw &>/dev/null; then
    echo -e "${RED}✗ OpenClaw not found. Install it first:${NC}"
    echo "  npm install -g openclaw@latest"
    echo "  openclaw onboard"
    exit 1
fi
echo -e "${GREEN}✓ OpenClaw found: $(openclaw --version 2>/dev/null || echo 'installed')${NC}"

# ── Collect credentials ─────────────────────────────────────
echo ""
echo -e "${BOLD}📋 Configuration Setup${NC}"
echo "──────────────────────────────────────────"

# GLM API Key
echo ""
echo -e "${YELLOW}Your GLM API key (from open.bigmodel.cn or z.ai):${NC}"
read -r -p "GLM API Key: " GLM_API_KEY
if [ -z "$GLM_API_KEY" ]; then
    echo -e "${RED}✗ GLM API key is required${NC}"
    exit 1
fi

# Telegram Bot Tokens — 5 bots, one per persona
echo ""
echo -e "${BOLD}🤖 Telegram Bot Tokens${NC}"
echo "──────────────────────────────────────────"
echo "You need 5 bots. Create them all at @BotFather with /newbot"
echo "Suggested names and usernames:"
echo ""
echo "  1. FORGE Orchestrator  → e.g. @ForgeOrchestratorBot  (talks to YOU)"
echo "  2. Alex (PM)           → e.g. @AlexPMBot             (requirements & docs)"
echo "  3. Sam (Architect)     → e.g. @SamArchitectBot       (system design)"
echo "  4. Jordan (Developer)  → e.g. @JordanDevBot          (writes code)"
echo "  5. Riley (Tester)      → e.g. @RileyQABot            (tests & bugs)"
echo ""
echo "Tip: You can add all 5 to a Telegram group later to watch them collaborate."
echo ""

read -r -p "1. FORGE Orchestrator bot token: " TOKEN_FORGE
read -r -p "2. Alex (PM Agent) bot token:    " TOKEN_PM
read -r -p "3. Sam (Architect) bot token:    " TOKEN_ARCH
read -r -p "4. Jordan (Developer) bot token: " TOKEN_DEV
read -r -p "5. Riley (Tester) bot token:     " TOKEN_TEST

# Validate all 5 tokens provided
for TOKEN_VAR in TOKEN_FORGE TOKEN_PM TOKEN_ARCH TOKEN_DEV TOKEN_TEST; do
    if [ -z "${!TOKEN_VAR}" ]; then
        echo -e "${RED}✗ All 5 bot tokens are required.${NC}"
        echo "  Create them at @BotFather → /newbot"
        exit 1
    fi
done
echo -e "${GREEN}✓ All 5 bot tokens collected${NC}"

# Detect GLM endpoint
echo ""
echo -e "${YELLOW}Which GLM platform are you using?${NC}"
echo "  1) Zhipu AI (open.bigmodel.cn) — Chinese platform"
echo "  2) Z.AI (api.z.ai) — International platform"
read -r -p "Choice [1/2]: " GLM_PLATFORM
if [ "$GLM_PLATFORM" = "2" ]; then
    GLM_BASE_URL="https://api.z.ai/api/paas/v4"
    GLM_PROVIDER_KEY="zai"
    echo -e "${GREEN}→ Using Z.AI endpoint${NC}"
else
    GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
    GLM_PROVIDER_KEY="zhipu"
    echo -e "${GREEN}→ Using Zhipu AI endpoint${NC}"
fi

# ── Create directory structure ───────────────────────────────
echo ""
echo -e "${YELLOW}▶ Creating workspace structure...${NC}"

mkdir -p "$WORKSPACE_DIR"/{agents,projects}

# Install skills
mkdir -p "$WORKSPACE_DIR/skills"
cp -r "$SCRIPT_DIR/skills/"* "$WORKSPACE_DIR/skills/"
echo -e "${GREEN}✓ Skills installed${NC}"

# Install agent system prompts (SOUL + role merged)
echo -e "${YELLOW}▶ Installing agent prompts...${NC}"

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

merge_agent "$SCRIPT_DIR/agents/pm-soul.md"        "$SCRIPT_DIR/agents/pm.md"        "$WORKSPACE_DIR/agents/pm.md"
merge_agent "$SCRIPT_DIR/agents/architect-soul.md" "$SCRIPT_DIR/agents/architect.md" "$WORKSPACE_DIR/agents/architect.md"
merge_agent "$SCRIPT_DIR/agents/developer-soul.md" "$SCRIPT_DIR/agents/developer.md" "$WORKSPACE_DIR/agents/developer.md"
merge_agent "$SCRIPT_DIR/agents/tester-soul.md"    "$SCRIPT_DIR/agents/tester.md"    "$WORKSPACE_DIR/agents/tester.md"
echo -e "${GREEN}✓ Agent prompts installed (with personalities)${NC}"

# Install SOUL.md and AGENTS.md
cp "$SCRIPT_DIR/SOUL.md"   "$WORKSPACE_DIR/SOUL.md"
cp "$SCRIPT_DIR/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
echo -e "${GREEN}✓ Orchestrator identity installed${NC}"

# ── Write openclaw.json ──────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Writing OpenClaw configuration...${NC}"

BACKUP_FILE=""
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
    BACKUP_FILE="$OPENCLAW_DIR/openclaw.json.backup.$(date +%s)"
    cp "$OPENCLAW_DIR/openclaw.json" "$BACKUP_FILE"
    echo -e "${YELLOW}  ⚠ Existing config backed up to: $BACKUP_FILE${NC}"
fi

# Read existing config if present and merge, otherwise use template
cat > /tmp/forge-patch.json << JSONEOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "${GLM_PROVIDER_KEY}": {
        "baseUrl": "${GLM_BASE_URL}",
        "apiKey": "${GLM_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${GLM_PROVIDER_KEY}/glm-4",
            "name": "GLM-4",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0.001, "output": 0.001 },
            "contextWindow": 128000,
            "maxTokens": 4096
          },
          {
            "id": "${GLM_PROVIDER_KEY}/glm-4-air",
            "name": "GLM-4-Air",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0.0001, "output": 0.0001 },
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${GLM_PROVIDER_KEY}/glm-4",
        "fallbacks": ["${GLM_PROVIDER_KEY}/glm-4-air"]
      },
      "workspace": "${WORKSPACE_DIR}",
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 },
      "compaction": { "mode": "safeguard" }
    },
    "named": {
      "pm-agent": {
        "model": { "primary": "${GLM_PROVIDER_KEY}/glm-4" },
        "systemPromptFile": "${WORKSPACE_DIR}/agents/pm.md",
        "channel": "pm"
      },
      "architect-agent": {
        "model": { "primary": "${GLM_PROVIDER_KEY}/glm-4" },
        "systemPromptFile": "${WORKSPACE_DIR}/agents/architect.md",
        "channel": "architect"
      },
      "developer-agent": {
        "model": { "primary": "${GLM_PROVIDER_KEY}/glm-4" },
        "systemPromptFile": "${WORKSPACE_DIR}/agents/developer.md",
        "channel": "developer"
      },
      "tester-agent": {
        "model": { "primary": "${GLM_PROVIDER_KEY}/glm-4" },
        "systemPromptFile": "${WORKSPACE_DIR}/agents/tester.md",
        "channel": "tester"
      }
    }
  },
  "channels": {
    "telegram": {
      "accounts": {
        "forge":     { "token": "${TOKEN_FORGE}" },
        "pm":        { "token": "${TOKEN_PM}" },
        "architect": { "token": "${TOKEN_ARCH}" },
        "developer": { "token": "${TOKEN_DEV}" },
        "tester":    { "token": "${TOKEN_TEST}" }
      }
    }
  },
  "messages": { "ackReactionScope": "all" },
  "commands": { "native": "auto", "nativeSkills": "auto" },
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": { "session-memory": { "enabled": true } }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback"
  }
}
JSONEOF

# Use openclaw config apply if available, otherwise write directly
if openclaw config apply /tmp/forge-patch.json 2>/dev/null; then
    echo -e "${GREEN}✓ Config applied via openclaw config${NC}"
else
    # Fall back to direct write if config apply not available
    cp /tmp/forge-patch.json "$OPENCLAW_DIR/openclaw.json"
    echo -e "${GREEN}✓ Config written directly${NC}"
fi

rm -f /tmp/forge-patch.json

# ── Validate config ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Validating configuration...${NC}"
if openclaw doctor 2>&1 | grep -q "error\|Error\|FAIL"; then
    echo -e "${YELLOW}  ⚠ Doctor found issues — run 'openclaw doctor --fix' to repair${NC}"
else
    echo -e "${GREEN}✓ Configuration valid${NC}"
fi

# ── Set file permissions ─────────────────────────────────────
chmod 700 "$OPENCLAW_DIR"
chmod 600 "$OPENCLAW_DIR/openclaw.json"
chmod 700 "$WORKSPACE_DIR"

# ── Print summary ────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ✅ FORGE Virtual Team — Setup Complete!    ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Your 5-bot team:${NC}"
echo "  🤖 FORGE (Orchestrator) — your main contact"
echo "  📋 Alex  (PM Agent)     — requirements & docs"
echo "  🏗️  Sam   (Architect)    — system design"
echo "  💻 Jordan (Developer)   — writes code"
echo "  🧪 Riley  (Tester)      — finds bugs"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Start OpenClaw:  openclaw gateway"
echo ""
echo "  2. Message your FORGE bot on Telegram"
echo "     Type /new to start your first project"
echo ""
echo -e "${BOLD}🔥 Group Chat Setup (optional but awesome):${NC}"
echo "  1. Create a new Telegram group"
echo "  2. Add all 5 bots to the group"
echo "  3. Give each bot admin rights (so they can tag each other)"
echo "  4. Watch Alex, Sam, Jordan & Riley collaborate in real time"
echo "  5. You stay in the group too — approve stages, give feedback"
echo ""
if [ -n "$BACKUP_FILE" ]; then
    echo -e "${YELLOW}Note: Your previous config was backed up to:${NC}"
    echo "  $BACKUP_FILE"
    echo ""
fi
echo -e "${BLUE}Happy building! 🦞${NC}"
echo ""
