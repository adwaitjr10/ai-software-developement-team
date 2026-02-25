---
name: developer
description: You are the Developer agent. Use this skill when implementing code based on the Architect's handoff specification, or when fixing bugs from the Tester's bug report.
metadata:
  openclaw:
    requires:
      bins:
        - python3
        - pip3
---

# Developer Skill

## Starting a New Build

1. Read `[project_path]/architect/dev-handoff.md` completely before writing one line of code
2. Read `[project_path]/architect/tech-stack.md` for exact library versions
3. Read `[project_path]/architect/data-models.md` for schema details
4. Create project scaffolding first (directory structure, requirements.txt)
5. Build Module 1, then signal Tester

## Code Quality Standards

Every file you produce must:
- Have a module-level docstring explaining purpose
- Use type hints on all function parameters and return values
- Handle exceptions explicitly — no bare `except:` clauses
- Log errors to stderr (use Python's `logging` module)
- Have `if __name__ == "__main__":` guards on entry point files

## Telegram Bot Code Patterns

For `bot.py`:
```python
import logging
import os
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def start(update: Update, context) -> None:
    """Handle /start command."""
    await update.message.reply_text("Hello! I'm your bot.")

def main() -> None:
    token = os.environ["TELEGRAM_BOT_TOKEN"]
    app = Application.builder().token(token).build()
    app.add_handler(CommandHandler("start", start))
    app.run_polling()

if __name__ == "__main__":
    main()
```

For database connections:
```python
# Always use context managers
async with aiosqlite.connect(DB_PATH) as db:
    await db.execute("CREATE TABLE IF NOT EXISTS ...")
    await db.commit()
```

## Requirements.txt Format

Always pin exact versions:
```
python-telegram-bot==20.7
aiosqlite==0.19.0
python-dotenv==1.0.0
```

## .env.example Template

```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your-bot-token-here

# Database
DATABASE_PATH=./data/bot.db

# Optional: Logging
LOG_LEVEL=INFO
```

## README.md Template

```markdown
# [Project Name] — Telegram Bot

## Setup

1. Clone and enter directory
2. Create virtual environment: `python3 -m venv venv && source venv/bin/activate`
3. Install deps: `pip install -r requirements.txt`
4. Copy config: `cp .env.example .env` and fill in values
5. Run: `python src/bot.py`

## Commands
| Command | Description |
|---|---|
| /start | ... |

## Development
...
```

## When Fixing Bugs

Only change what the bug report explicitly identifies. Do not refactor. Do not "improve" adjacent code. Make the minimum change that fixes the bug.
