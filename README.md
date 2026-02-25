# 🦾 FORGE — Virtual Software Team for OpenClaw (v2)

A team of **4 world-class AI agents** (each with 12-15+ years of domain expertise) that lives in **OpenClaw**, collaborates visibly through **Telegram group chat**, and is powered by **GLM-4**.

```
You (Telegram) ←→ FORGE Orchestrator
                      ↓
              ┌───────────────────────────────┐
              │  📋 PM (12yr)       → BRD, SOW, FSD           │
              │  🏗️ Architect (15yr) → Battle-tested Design    │
              │  💻 Developer (15yr) → Security-first Code     │
              │  🧪 Tester (15yr)    → OWASP + 5-Gate QA      │
              └───────────────────────────────┘
                      ↓
              💬 Telegram Group Chat
              (watch all bots collaborate in real-time)
```

---

## What Makes This Team Special

| Agent | Expertise | What They Do That Generic Bots Don't |
|---|---|---|
| **PM** | 12+ years product management | Uncovers REAL requirements (not just stated ones), MoSCoW + RICE prioritization, Given/When/Then acceptance criteria |
| **Architect** | 15+ years system design | Failure mode analysis for every component, database/architecture/API selection matrices, scalability roadmap |
| **Developer** | 15+ years engineering | OWASP-aware security-first coding, retry/circuit breaker patterns, cursor pagination, N+1 prevention, proper error handling |
| **Tester** | 15+ years QA/security | 5-gate quality process: static analysis → security audit → functional testing → integration → performance |

---

## Prerequisites

- Linux or macOS
- Node.js ≥ 22 (`node --version`)
- OpenClaw installed: `npm install -g openclaw@latest`
- OpenClaw onboarded: `openclaw onboard`
- **5 Telegram bot tokens** from [@BotFather](https://t.me/BotFather) (one per agent)
- A GLM-4 API key from [open.bigmodel.cn](https://open.bigmodel.cn) or [z.ai](https://z.ai)

---

## Installation

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
1. Collect your API key and 5 bot tokens
2. Optionally set up Telegram group chat collaboration
3. Install world-class agent prompts
4. Configure OpenClaw with all agents and channels

---

## Starting the Team

```bash
# Start OpenClaw gateway (keeps running in terminal)
openclaw gateway

# Or start as background daemon
openclaw gateway start
```

Then message your FORGE Orchestrator bot on Telegram. It will respond as **FORGE**.

---

## Using FORGE

### Start a Project

Send `/new` to your bot, or just describe what you want:

> "Build me a Telegram task manager bot with reminders"

FORGE will start the PM agent to interview you about requirements.

### Pipeline Flow

```
1. PM Interview (5-15 min chat)
       ↓ You approve BRD/SOW/FSD
2. Architect Design (automated)
       ↓ You approve architecture  
3. Developer builds code (automated, module by module)
   ↔ Tester tests each module (5-gate quality check, auto-loop)
       ↓ You approve final delivery
4. Done — production-ready code in your workspace
```

### Approval Commands

At each stage you'll get a summary and options:
- ✅ `/approve` — proceed to next stage
- 🔄 `/changes [feedback]` — request revisions
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

## 💬 Telegram Group Chat (The Magic)

This is the killer feature: add all 5 bots to a Telegram group and **watch them collaborate in real-time**.

### Setup

1. **Create a Telegram group** (e.g., "FORGE Team")
2. **Add all 5 bots** to the group
3. **Give each bot admin rights** (so they can send messages)
4. **Get the Group Chat ID:**
   ```
   # Send any message in the group, then:
   curl https://api.telegram.org/bot<FORGE_BOT_TOKEN>/getUpdates | jq '.result[-1].message.chat.id'
   ```
   The ID is a negative number like `-1001234567890`
5. **Run setup.sh** and enter the Group Chat ID when prompted
   (or add it to `~/.openclaw/openclaw.json` manually)

### What You'll See

Once set up, the bots post in the group as they work:

```
📋 PM: Starting requirements interview for "TaskBot"...
📋 PM: ✅ Requirements complete. BRD, SOW, FSD ready.
🏗️ Architect: Designing system architecture...
🏗️ Architect: ✅ Architecture locked. SQLite + python-telegram-bot.
💻 Developer: Building Module 1 (database layer)...
💻 Developer: ✅ Module 1 complete. Handing to Tester.
🧪 Tester: Running 5-gate quality check on Module 1...
🧪 Tester: ❌ 2 bugs found (1 High, 1 Medium). Sending to Developer.
💻 Developer: ✅ Fixes applied. Ready for re-test.
🧪 Tester: ✅ Module 1 ALL PASS. 12 criteria verified.
🎉 FORGE: ALL MODULES PASSED! Ready for delivery review.
```

---

## File Structure

```
~/.openclaw/
├── openclaw.json              ← Main config (GLM-4, Telegram, agents, group chat)
└── workspace/
    ├── SOUL.md                ← FORGE personality (orchestrator)
    ├── AGENTS.md              ← Orchestrator behavior + group chat protocol
    ├── agents/
    │   ├── pm.md              ← PM: 12yr expert, deep requirements discovery
    │   ├── architect.md       ← Architect: 15yr expert, failure-mode design
    │   ├── developer.md       ← Developer: 15yr expert, security-first code
    │   └── tester.md          ← Tester: 15yr expert, OWASP + 5-gate QA
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
            ├── pm/            ← BRD, SOW, FSD (Given/When/Then criteria)
            ├── architect/     ← Tech design + failure mode analysis
            ├── developer/     ← Production-ready source code
            └── tester/        ← Test reports + security audit results
```

---

## Agent Quality Highlights

### Developer writes code like this:
- ✅ Parameterized SQL queries (no injection)
- ✅ Retry with exponential backoff on external calls
- ✅ Cursor-based pagination (stable under concurrent writes)
- ✅ Proper error boundaries with specific exception handling
- ✅ Environment variables for ALL secrets (fail-fast if missing)
- ✅ Type hints on every function

### Tester runs 5 quality gates:
1. **Static Analysis** — syntax, imports, types, code quality
2. **Security Audit** — SQL injection, XSS, hardcoded secrets, input validation
3. **Functional Testing** — happy path + systematic edge cases
4. **Integration Check** — module interfaces, data model consistency
5. **Performance** — N+1 queries, pagination, resource cleanup

### Architect designs for reality:
- Every component has a documented failure mode and recovery strategy
- Database selection backed by requirements (not opinion)
- Scalability roadmap: "here's what to do when you outgrow v1"
- Security architecture from day 1 (auth, tokens, RBAC)

---

## GLM-4 Configuration Notes

FORGE uses **GLM-4** as the primary model for all agents, with **GLM-4-Air** as fallback.

| Platform | Base URL | When to use |
|---|---|---|
| Zhipu AI | `https://open.bigmodel.cn/api/paas/v4` | If you have a Zhipu key |
| Z.AI | `https://api.z.ai/api/paas/v4` | If you have a Z.AI key |

---

## Troubleshooting

**Bot doesn't respond in Telegram:**
```bash
openclaw doctor --fix
openclaw logs
```

**Bots not posting in group chat:**
- Verify all 5 bots have admin rights in the group
- Check the Group Chat ID is correct (negative number)
- Verify `channels.telegram.groupChat.enabled` is `true` in `openclaw.json`

**GLM API authentication error:**
```bash
cat ~/.openclaw/openclaw.json | grep apiKey
./setup.sh  # Re-run if wrong
```

**Agent not spawning:**
```bash
openclaw config get agents.named
```

**Reset everything:**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak
./setup.sh
```

---

Built with OpenClaw 🦞 + GLM-4 🤖 — World-class AI agents, not generic bots.
