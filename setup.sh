#!/bin/bash
# ============================================================
#  FORGE Virtual Team — OpenClaw Setup Script
#  Run this ONCE to install the 4-agent software team
#  with Telegram group chat collaboration
#
#  Correct OpenClaw config schema as of v2026.2.x
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
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║   FORGE Virtual Team — Setup Installer v2   ║${NC}"
echo -e "${BLUE}${BOLD}║   🔥 World-Class AI Agents + Group Chat     ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════╝${NC}"
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
echo "Each bot becomes a team member with its own identity:"
echo ""
echo "  1. FORGE Orchestrator  → e.g. @ForgeOrchestratorBot  (talks to YOU, coordinates team)"
echo "  2. Project Manager     → e.g. @ForgePMBot             (12+ yr PM, requirements expert)"
echo "  3. Architect           → e.g. @ForgeArchitectBot      (15+ yr architect, system design)"
echo "  4. Developer           → e.g. @ForgeDevBot            (15+ yr engineer, production code)"
echo "  5. Tester              → e.g. @ForgeQABot             (15+ yr QA, security & testing)"
echo ""
echo -e "${YELLOW}Tip: Add all 5 to a Telegram group to watch them collaborate in real-time!${NC}"
echo ""

read -r -p "1. FORGE Orchestrator bot token: " TOKEN_FORGE
read -r -p "2. Project Manager bot token:    " TOKEN_PM
read -r -p "3. Architect bot token:          " TOKEN_ARCH
read -r -p "4. Developer bot token:          " TOKEN_DEV
read -r -p "5. Tester bot token:             " TOKEN_TEST

# Validate all 5 tokens provided
for TOKEN_VAR in TOKEN_FORGE TOKEN_PM TOKEN_ARCH TOKEN_DEV TOKEN_TEST; do
    if [ -z "${!TOKEN_VAR}" ]; then
        echo -e "${RED}✗ All 5 bot tokens are required.${NC}"
        echo "  Create them at @BotFather → /newbot"
        exit 1
    fi
done
echo -e "${GREEN}✓ All 5 bot tokens collected${NC}"

# ── Group Chat Setup ────────────────────────────────────────
echo ""
echo -e "${BOLD}💬 Telegram Group Chat (for bot-to-bot collaboration)${NC}"
echo "──────────────────────────────────────────"
echo "Want your bots to visibly interact in a Telegram group?"
echo ""
echo -e "${YELLOW}To get your Group Chat ID:${NC}"
echo "  1. Create a Telegram group"
echo "  2. Add all 5 bots to the group"
echo "  3. Give each bot admin rights"
echo "  4. Send any message in the group"
echo "  5. Run: curl \"https://api.telegram.org/bot<FORGE_TOKEN>/getUpdates\" | python3 -m json.tool"
echo "  6. Look for 'chat':{'id': -XXXXXXXXX} — that negative number is your Group Chat ID"
echo ""
read -r -p "Group Chat ID (or press Enter to skip): " GROUP_CHAT_ID

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
echo -e "${GREEN}✓ Skills installed (orchestrator, developer, architect, tester, PM)${NC}"

# Install agent system prompts (SOUL + role merged)
echo -e "${YELLOW}▶ Installing world-class agent prompts...${NC}"

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
echo -e "${GREEN}✓ Agent prompts installed (world-class expertise + personalities)${NC}"

# Install SOUL.md and AGENTS.md
cp "$SCRIPT_DIR/SOUL.md"   "$WORKSPACE_DIR/SOUL.md"
cp "$SCRIPT_DIR/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
echo -e "${GREEN}✓ Orchestrator identity installed${NC}"

# ── Build group chat config snippet ──────────────────────────
# Only add group config if user provided a Group Chat ID
GROUP_CONFIG=""
if [ -n "$GROUP_CHAT_ID" ]; then
    GROUP_CONFIG=$(cat <<GROUPJSON
      "groupPolicy": "open",
      "groups": {
        "${GROUP_CHAT_ID}": {
          "groupPolicy": "open",
          "requireMention": false
        }
      },
GROUPJSON
)
fi

# ── Write openclaw.json ──────────────────────────────────────
echo ""
echo -e "${YELLOW}▶ Writing OpenClaw configuration...${NC}"

BACKUP_FILE=""
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
    BACKUP_FILE="$OPENCLAW_DIR/openclaw.json.backup.$(date +%s)"
    cp "$OPENCLAW_DIR/openclaw.json" "$BACKUP_FILE"
    echo -e "${YELLOW}  ⚠ Existing config backed up to: $BACKUP_FILE${NC}"
fi

# Write config using correct OpenClaw schema (v2026.2.x)
# Key schema rules:
#   - agents.list[] (array, not agents.named)
#   - channels.telegram.botToken (not accounts.*.token)
#   - channels.telegram.accounts.<name>.botToken (for multi-account)
#   - channels.telegram.groups."<id>" (for group chat config)
#   - bindings[] (for routing accounts to agents)
#   - No systemPromptFiles (OpenClaw reads from workspace automatically)

cat > "$OPENCLAW_DIR/openclaw.json" << JSONEOF
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
      "compaction": { "mode": "safeguard" },
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 }
    },
    "list": [
      {
        "id": "main",
        "name": "FORGE Orchestrator",
        "default": true,
        "workspace": "${WORKSPACE_DIR}",
        "identity": { "name": "FORGE", "emoji": "🦞" },
        "subagents": { "allowAgents": ["*"] }
      },
      {
        "id": "pm-agent",
        "name": "Project Manager",
        "workspace": "${WORKSPACE_DIR}",
        "identity": { "name": "PM", "emoji": "📋" }
      },
      {
        "id": "architect-agent",
        "name": "Architect",
        "workspace": "${WORKSPACE_DIR}",
        "identity": { "name": "Architect", "emoji": "🏗️" }
      },
      {
        "id": "developer-agent",
        "name": "Developer",
        "workspace": "${WORKSPACE_DIR}",
        "identity": { "name": "Developer", "emoji": "💻" }
      },
      {
        "id": "tester-agent",
        "name": "Tester",
        "workspace": "${WORKSPACE_DIR}",
        "identity": { "name": "Tester", "emoji": "🧪" }
      }
    ]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TOKEN_FORGE}",
      "dmPolicy": "pairing",
${GROUP_CONFIG}
      "accounts": {
        "pm": {
          "botToken": "${TOKEN_PM}"
        },
        "architect": {
          "botToken": "${TOKEN_ARCH}"
        },
        "developer": {
          "botToken": "${TOKEN_DEV}"
        },
        "tester": {
          "botToken": "${TOKEN_TEST}"
        }
      },
      "streaming": "off"
    }
  },
  "bindings": [
    {
      "match": { "channel": "telegram", "accountId": "pm" },
      "agentId": "pm-agent"
    },
    {
      "match": { "channel": "telegram", "accountId": "architect" },
      "agentId": "architect-agent"
    },
    {
      "match": { "channel": "telegram", "accountId": "developer" },
      "agentId": "developer-agent"
    },
    {
      "match": { "channel": "telegram", "accountId": "tester" },
      "agentId": "tester-agent"
    }
  ],
  "messages": { "ackReactionScope": "all" },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
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

echo -e "${GREEN}✓ Config written to $OPENCLAW_DIR/openclaw.json${NC}"

# ── Set file permissions ─────────────────────────────────────
chmod 700 "$OPENCLAW_DIR"
chmod 600 "$OPENCLAW_DIR/openclaw.json"
chmod 700 "$WORKSPACE_DIR"

# ── Print summary ────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ✅ FORGE Virtual Team v2 — Setup Complete!      ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Your 5-bot team of WORLD-CLASS experts:${NC}"
echo "  🦞 FORGE (Orchestrator)   — your CTO contact"
echo "  📋 Project Manager (12yr) — requirements & specs expert"
echo "  🏗️  Architect (15yr)       — system design master"
echo "  💻 Developer (15yr)        — security-first production coder"
echo "  🧪 Tester (15yr)           — OWASP security + 5-gate QA"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Start OpenClaw:  openclaw gateway"
echo ""
echo "  2. Message your FORGE bot on Telegram"
echo "     Type /new to start your first project"
echo ""
if [ -n "$GROUP_CHAT_ID" ]; then
    echo -e "${BOLD}💬 Group Chat: ENABLED${NC} (ID: $GROUP_CHAT_ID)"
    echo "  Your bots will collaborate visibly in the group chat!"
    echo "  Make sure all 5 bots have admin rights in the group."
    echo ""
else
    echo -e "${BOLD}💬 Group Chat Setup (do this for the full experience!):${NC}"
    echo "  1. Create a new Telegram group"
    echo "  2. Add all 5 bots to the group"
    echo "  3. Give each bot admin rights (so they can post)"
    echo "  4. Get the Group Chat ID:"
    echo "     → Send a message in the group"
    echo "     → Run: curl \"https://api.telegram.org/bot<TOKEN>/getUpdates\" | python3 -m json.tool"
    echo "     → Copy the 'chat.id' value (negative number)"
    echo "  5. Add to config: openclaw config set channels.telegram.groups.<ID>.groupPolicy open"
    echo ""
fi
echo -e "${BOLD}🔥 What makes this team special:${NC}"
echo "  • Developer writes security-first code (OWASP-aware, handles all edge cases)"
echo "  • Tester runs 5-gate quality checks (security audit, functional, performance)"
echo "  • Architect designs for failure (every component has a failure recovery plan)"
echo "  • PM writes Given/When/Then acceptance criteria (crystal-clear, testable specs)"
echo ""
if [ -n "$BACKUP_FILE" ]; then
    echo -e "${YELLOW}Note: Your previous config was backed up to:${NC}"
    echo "  $BACKUP_FILE"
    echo ""
fi
echo -e "${BLUE}Happy building! 🦞${NC}"
echo ""
