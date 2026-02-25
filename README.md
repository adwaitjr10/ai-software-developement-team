# 🦾 FORGE — Virtual Software Team for OpenClaw (v2)

A team of **4 world-class AI agents** (each with 12-15+ years of domain expertise) that lives in **OpenClaw**, collaborates visibly through **Telegram group chat**, and is powered by **GLM**.

```
You (Telegram) ←→ FORGE Orchestrator 🦞
                      ↓
              ┌───────────────────────────────────────┐
              │  📋 PM (12yr)       → BRD, SOW, FSD   │
              │  🏗️ Architect (15yr) → System Design   │
              │  💻 Developer (15yr) → Production Code │
              │  🧪 Tester (15yr)    → 5-Gate QA       │
              └───────────────────────────────────────┘
                      ↓
              💬 Telegram Group Chat
              (watch all bots collaborate in real-time)
```

---

## What Makes This Team Special

| Agent | What They Do That Generic Bots Don't |
|---|---|
| **PM** | Uncovers REAL requirements, MoSCoW + RICE prioritization, Given/When/Then acceptance criteria |
| **Architect** | Failure mode analysis per component, DB/architecture/API selection matrices, scalability roadmap |
| **Developer** | OWASP security-first coding, retry/circuit breaker patterns, cursor pagination, N+1 prevention |
| **Tester** | 5-gate quality: static analysis → OWASP security audit → functional → integration → performance |

---

## Prerequisites

| Requirement | How to Check | Install |
|---|---|---|
| **Node.js ≥ 22** | `node --version` | `nvm install 22 && nvm use 22` |
| **OpenClaw** | `openclaw --version` | `npm install -g openclaw@latest` |
| **5 Telegram bots** | Create at [@BotFather](https://t.me/BotFather) | `/newbot` for each agent |
| **GLM API key** | — | [open.bigmodel.cn](https://open.bigmodel.cn) or [z.ai](https://z.ai) |

> **⚠️ Node 22+ is required.** If you use nvm, run `nvm use 22` before any openclaw command.

---

## Installation

### Step 1: Install OpenClaw

```bash
nvm use 22              # Required — OpenClaw needs Node 22+
npm install -g openclaw@latest
openclaw onboard
```

### Step 2: Create 5 Telegram Bots

Open Telegram → message **@BotFather** → `/newbot` for each:

| # | Role | Suggested Username |
|---|---|---|
| 1 | FORGE Orchestrator | `@YourForgeBot` |
| 2 | Project Manager | `@YourForgePMBot` |
| 3 | Architect | `@YourForgeArchBot` |
| 4 | Developer | `@YourForgeDevBot` |
| 5 | Tester | `@YourForgeQABot` |

Save each bot token that BotFather gives you.

### Step 3: Get a GLM API Key

Sign up at one of:
- 🇨🇳 [open.bigmodel.cn](https://open.bigmodel.cn) (Zhipu AI — has `glm-4`)
- 🌍 [z.ai](https://z.ai) (International — has `glm-5`, `glm-4.5-air`)

> **Note:** Z.AI and Zhipu have **different model names**. The setup script handles this automatically.

### Step 4: Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

The script will ask for:
1. Your GLM API key
2. All 5 bot tokens
3. Which GLM platform (Zhipu or Z.AI)
4. (Optional) Telegram group chat ID

### Step 5: Set Up Group Chat (Optional but recommended)

1. Create a Telegram group (e.g., "FORGE Team")
2. Add all 5 bots to the group
3. Make each bot admin
4. Send any message in the group
5. Get the Group Chat ID:
   ```bash
   curl "https://api.telegram.org/bot<YOUR_FORGE_TOKEN>/getUpdates" | python3 -m json.tool
   ```
   Look for `"chat": {"id": -XXXXXXXXX}` — that negative number is your Group Chat ID.
6. Enter it when `setup.sh` asks, or add it later:
   ```bash
   nvm use 22
   openclaw config set 'channels.telegram.groups."-YOUR_GROUP_ID".groupPolicy' open
   openclaw config set 'channels.telegram.groups."-YOUR_GROUP_ID".requireMention' false
   ```

---

## Starting & Stopping

```bash
./start.sh    # Start the FORGE gateway
./stop.sh     # Stop the FORGE gateway
```

Or manually:
```bash
nvm use 22
openclaw gateway          # Start (foreground)
openclaw gateway stop     # Stop
```

Then message your FORGE bot on Telegram and type `/new` to start a project.

---

## Using FORGE

### Commands

| Command | Description |
|---|---|
| `/new` | Start a new project |
| `/status` | Current pipeline stage |
| `/projects` | List all projects |
| `/approve` | Approve current stage |
| `/changes [feedback]` | Request changes |

### Pipeline Flow

```
1. PM Interview (5-15 min chat)
       ↓ You approve BRD/SOW/FSD
2. Architect Design (automated)
       ↓ You approve architecture
3. Developer builds code (module by module)
   ↔ Tester tests each module (auto-loop)
       ↓ You approve final delivery
4. Done — production-ready code
```

### Group Chat Experience

When set up, your Telegram group becomes a live dev team feed:

```
📋 PM: Starting requirements interview for "TaskBot"...
📋 PM: ✅ Requirements complete. BRD, SOW, FSD ready.
🏗️ Architect: Designing system architecture...
🏗️ Architect: ✅ Architecture locked. SQLite + python-telegram-bot.
💻 Developer: Building Module 1 (database layer)...
🧪 Tester: Running 5-gate quality check...
🧪 Tester: ❌ 2 bugs found. Sending to Developer.
💻 Developer: ✅ Fixes applied. Ready for re-test.
🧪 Tester: ✅ Module 1 ALL PASS.
🎉 FORGE: ALL MODULES PASSED! Ready for delivery.
```

---

## File Structure

```
virtual-team-setup-2/
├── setup.sh               ← Run once to install everything
├── start.sh               ← Start the gateway
├── stop.sh                ← Stop the gateway
├── openclaw.json          ← Config template (placeholder values)
├── SOUL.md                ← FORGE Orchestrator personality
├── AGENTS.md              ← Pipeline + group chat protocol
├── README.md              ← You are here
├── agents/
│   ├── pm-soul.md         ← PM personality
│   ├── pm.md              ← PM role + deep expertise
│   ├── architect-soul.md  ← Architect personality
│   ├── architect.md       ← Architect role + expertise
│   ├── developer-soul.md  ← Developer personality
│   ├── developer.md       ← Developer role + expertise
│   ├── tester-soul.md     ← Tester personality
│   └── tester.md          ← Tester role + expertise
└── skills/
    ├── virtual-team-orchestrator/SKILL.md
    ├── project-state/SKILL.md
    ├── project-manager/SKILL.md
    ├── architect/SKILL.md
    ├── developer/SKILL.md
    └── tester/SKILL.md
```

After setup, your installed workspace lives at:
```
~/.openclaw/
├── openclaw.json          ← Your REAL config (with tokens)
└── workspace/
    ├── SOUL.md, AGENTS.md
    ├── agents/            ← Merged soul+role prompts
    ├── skills/            ← All skill playbooks
    └── projects/          ← Created project artifacts
```

---

## GLM Model Reference

| Platform | Available Models | Recommended |
|---|---|---|
| **Z.AI** | `glm-5`, `glm-4.7`, `glm-4.6`, `glm-4.5`, `glm-4.5-air` | Primary: `glm-5`, Fallback: `glm-4.5-air` |
| **Zhipu AI** | `glm-4`, `glm-4-air`, `glm-4-flash` | Primary: `glm-4`, Fallback: `glm-4-air` |

To change your model after setup:
```bash
nvm use 22
openclaw config set agents.defaults.model.primary "zai/glm-4.5-air"
```

---

## Troubleshooting

**"command not found: openclaw"**
```bash
nvm use 22    # OpenClaw needs Node 22+
```

**"gateway already running"**
```bash
./stop.sh     # Force stops the gateway
./start.sh    # Start fresh
```

**"API rate limit reached"**
- Wait 60 seconds and try again
- Switch to a cheaper model: `openclaw config set agents.defaults.model.primary "zai/glm-4.5-air"`
- Check your API plan at z.ai or open.bigmodel.cn

**"Unknown Model"**
- Z.AI doesn't have `glm-4` — use `glm-5` or `glm-4.5-air`
- Zhipu doesn't have `glm-5` — use `glm-4`
- Check available models: `curl "https://api.z.ai/api/paas/v4/models" -H "Authorization: Bearer YOUR_KEY"`

**Bots not responding in group**
- Make each bot admin in the group
- Disable privacy mode: @BotFather → `/setprivacy` → select bot → Disable

**Reset everything**
```bash
./stop.sh
rm ~/.openclaw/openclaw.json
./setup.sh
```

---

Built with [OpenClaw](https://openclaw.ai) 🦞 — World-class AI agents, not generic bots.
