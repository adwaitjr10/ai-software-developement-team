# 🦾 FORGE — Virtual Software Team for OpenClaw

A complete 4-agent AI software team that lives in **OpenClaw** and communicates through **Telegram**, powered by **GLM-4**.

```
You (Telegram) ←→ FORGE Orchestrator
                      ↓
              ┌───────────────────┐
              │  PM Agent         │ → BRD, SOW, FSD
              │  Architect Agent  │ → Tech Design, Handoff
              │  Developer Agent  │ → Source Code
              │  Tester Agent     │ → Bug Reports, Results
              └───────────────────┘
```

---

## Prerequisites

- Linux (Ubuntu/Debian recommended)
- Node.js ≥ 22 (`node --version`)
- OpenClaw installed: `npm install -g openclaw@latest`
- OpenClaw onboarded: `openclaw onboard` (at least partially)
- A Telegram bot token from [@BotFather](https://t.me/BotFather)
- A GLM-4 API key from [open.bigmodel.cn](https://open.bigmodel.cn) or [z.ai](https://z.ai)

---

## Installation

```bash
chmod +x setup.sh
./setup.sh
```

The script will ask for your API key and Telegram token, then install everything.

---

## Starting the Team

```bash
# Start OpenClaw gateway (keeps running in terminal)
openclaw gateway

# Or start as background daemon
openclaw gateway start
```

Then message your Telegram bot. It will respond as **FORGE**.

---

## Using FORGE

### Start a Project

Send `/new` to your bot, or just describe what you want:

> "Build me a Telegram task manager bot with reminders"

FORGE will start the PM agent to interview you about requirements.

### Pipeline Flow

```
1. PM Interview (5-10 min chat)
       ↓ You approve BRD/SOW/FSD
2. Architect Design (automated)
       ↓ You approve architecture  
3. Developer builds code (automated, module by module)
   ↔ Tester tests each module (auto-loop)
       ↓ You approve final delivery
4. Done — code is in your workspace
```

### Approval Commands

At each stage you'll get a summary and options:
- ✅ `/approve` — proceed to next stage
- 🔄 `/changes [feedback]` — request revisions (e.g., `/changes please add user authentication`)
- ❌ `/reject [reason]` — stop and discuss

### Other Commands

| Command | Description |
|---|---|
| `/new` | Start a new project |
| `/status` | Current pipeline stage |
| `/projects` | List all your projects |
| `/approve` | Approve current stage |
| `/changes [text]` | Request changes with feedback |

---

## File Structure

```
~/.openclaw/
├── openclaw.json              ← Main config (GLM-4, Telegram, named agents)
└── workspace/
    ├── SOUL.md                ← FORGE personality
    ├── AGENTS.md              ← Orchestrator behavior
    ├── agents/
    │   ├── pm.md              ← PM agent system prompt
    │   ├── architect.md       ← Architect agent system prompt
    │   ├── developer.md       ← Developer agent system prompt
    │   └── tester.md          ← Tester agent system prompt
    ├── skills/
    │   ├── virtual-team-orchestrator/SKILL.md
    │   ├── project-state/SKILL.md
    │   ├── project-manager/SKILL.md
    │   ├── architect/SKILL.md
    │   ├── developer/SKILL.md
    │   └── tester/SKILL.md
    └── projects/
        └── proj-[timestamp]/
            ├── project.json   ← Pipeline state
            ├── pm/            ← BRD, SOW, FSD
            ├── architect/     ← Tech design docs
            ├── developer/     ← Source code
            └── tester/        ← Test reports
```

---

## GLM-4 Configuration Notes

FORGE uses **GLM-4** as the primary model for all 4 agents, with **GLM-4-Air** as fallback.

| Platform | Base URL | When to use |
|---|---|---|
| Zhipu AI | `https://open.bigmodel.cn/api/paas/v4` | If you have a Zhipu key |
| Z.AI | `https://api.z.ai/api/paas/v4` | If you have a Z.AI key |

The setup script detects which you're using. If you need to switch later, edit `~/.openclaw/openclaw.json` and update the `baseUrl` in `models.providers`.

---

## Troubleshooting

**Bot doesn't respond in Telegram:**
```bash
openclaw doctor --fix
openclaw logs
```

**GLM API authentication error:**
```bash
# Check your API key is set correctly
cat ~/.openclaw/openclaw.json | grep apiKey
# Re-run setup if wrong
./setup.sh
```

**Agent not spawning:**
```bash
# Verify named agents are configured
openclaw config get agents.named
```

**Reset everything:**
```bash
# Backup current config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak
# Re-run setup
./setup.sh
```

---

## Adding More Telegram Bots (Optional)

If you want each agent to have its own Telegram bot token, edit `openclaw.json`:

```json
"channels": {
  "telegram": {
    "accounts": {
      "main":      { "token": "YOUR_MAIN_BOT_TOKEN" },
      "pm":        { "token": "YOUR_PM_BOT_TOKEN" },
      "architect": { "token": "YOUR_ARCHITECT_BOT_TOKEN" },
      "developer": { "token": "YOUR_DEV_BOT_TOKEN" },
      "tester":    { "token": "YOUR_TESTER_BOT_TOKEN" }
    }
  }
}
```

Then add `"channel": "pm"` to each named agent config.

---

## Architecture Notes

- **Single process** — One OpenClaw gateway manages all 4 agents
- **Sub-agents** — Each agent is a named OpenClaw session spawned with `sessions_spawn`
- **Shared state** — `project.json` in each project folder tracks pipeline stage
- **No external services** — No Redis, no separate processes, no database server needed
- **File-based artifacts** — All PM docs, architecture, code, and test reports saved as files

---

Built with OpenClaw 🦞 + GLM-4 🤖
