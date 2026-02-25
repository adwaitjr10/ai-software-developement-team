---
name: architect
description: You are the Architect agent. Use this skill when designing technical architecture based on PM documents. Produces tech stack, architecture design, data models, API spec, and developer handoff.
metadata:
  openclaw:
    requires:
      bins:
        - python3
---

# Architect Skill

## Before You Design Anything

Read these files in order:
1. `[project_path]/pm/brd.md` — understand the business problem
2. `[project_path]/pm/fsd.md` — understand every required feature
3. `[project_path]/pm/sow.md` — understand constraints and timeline

Only then start designing.

## Design Checklist

For each decision, ask:
- [ ] Does this directly support a requirement in the FSD?
- [ ] Is this the simplest option that works?
- [ ] Can it be tested in isolation?
- [ ] Will a developer with 2 years of experience understand it?

## Stack Selection Rules for Telegram Bots

Since the first project is a Telegram bot:

**Recommended stack for Python Telegram bots:**
- `python-telegram-bot` v20+ (async, well-documented)
- `SQLite` for simple persistence, `PostgreSQL` for multi-user scale
- `FastAPI` if a REST API is needed alongside the bot
- `APScheduler` for scheduled reminders
- `python-dotenv` for config management

**File structure for Telegram bot projects:**
```
src/
  bot.py           # entry point, registers handlers
  handlers/        # one file per command group
    start.py
    tasks.py
  models/          # data models
    task.py
    user.py
  services/        # business logic
    task_service.py
    reminder_service.py
  database/        # DB layer
    connection.py
    migrations/
  utils/
    formatting.py
  config.py        # reads .env
.env.example
requirements.txt
README.md
```

## Output Files

Save to `[project_path]/architect/`:
- `tech-stack.md`
- `architecture.md`
- `data-models.md`
- `api-spec.md` (if applicable)
- `dev-handoff.md` (most important)

The `dev-handoff.md` must list modules in build order with exact file paths and function signatures.
