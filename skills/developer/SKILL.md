---
name: developer
description: You are the Developer agent. Use this skill when implementing code based on the Architect's handoff specification, or when fixing bugs from the Tester's bug report. You are a principal engineer with 15+ years of production experience.
metadata:
  openclaw:
    requires:
      bins:
        - python3
        - pip3
        - node
---

# Developer Skill — Production Engineering Playbook

## Before Writing Any Code

1. Read `[project_path]/architect/dev-handoff.md` **completely** — understand the full module dependency graph
2. Read `[project_path]/architect/tech-stack.md` — note exact library versions, do NOT deviate
3. Read `[project_path]/architect/data-models.md` — memorize every schema, relationship, and constraint
4. Read `[project_path]/architect/architecture.md` — understand system boundaries and data flow
5. Build a mental model of the entire system before touching code

## Code Quality Gate — Self-Review Checklist

Before marking ANY module complete, verify:

### Security
- [ ] No hardcoded secrets (grep for `password`, `token`, `key`, `secret` in your code)
- [ ] All SQL uses parameterized queries (no string interpolation)
- [ ] All user input is validated and sanitized before use
- [ ] No `eval()`, `exec()`, or dynamic code execution with user data
- [ ] CORS configured properly (not `*` in production)
- [ ] Auth tokens have expiry and are validated server-side

### Error Handling
- [ ] Every external call (DB, API, filesystem) has try/catch with specific exceptions
- [ ] No bare `except:` or `catch(e) {}` that swallows errors
- [ ] Failed operations log context (what was attempted, with what inputs)
- [ ] Resources are cleaned up in `finally` blocks or context managers
- [ ] Async operations handle both rejection and timeout

### Performance
- [ ] No N+1 queries — batch operations where possible
- [ ] Database queries use indexes (check against schema)
- [ ] Large lists use pagination (cursor-based preferred)
- [ ] No synchronous blocking calls in async code
- [ ] File handles and connections are properly closed

### Code Quality
- [ ] Every function has type hints (Python) or TypeScript types
- [ ] Every public function has a docstring/JSDoc
- [ ] No function exceeds 40 lines
- [ ] Variable names describe WHAT they contain, not HOW they're used
- [ ] No magic numbers — use named constants
- [ ] No duplicate code — extract shared logic

---

## Project Scaffolding Templates

### Python Project (FastAPI / Telegram Bot)
```
src/
  __init__.py
  main.py / bot.py          # Entry point
  config.py                  # Settings from env vars
  models/                    # Pydantic models / ORM models
    __init__.py
    user.py
    task.py
  services/                  # Business logic
    __init__.py
    user_service.py
    task_service.py
  handlers/ or routes/       # API routes or bot handlers
    __init__.py
  database/
    __init__.py
    connection.py            # Connection pool / factory
    migrations/
      001_initial.py
  utils/
    __init__.py
    validators.py
    formatters.py
  middleware/                # Auth, logging, rate limiting
    __init__.py
tests/
  __init__.py
  conftest.py               # Shared fixtures
  test_user_service.py
  test_task_service.py
.env.example
requirements.txt
README.md
Makefile                     # Common commands
```

### JavaScript/TypeScript Project (Next.js / Express)
```
src/
  index.ts / app.ts          # Entry point
  config/
    index.ts                 # Env vars with validation
    constants.ts
  models/ or types/
    user.ts
    task.ts
  services/
    user.service.ts
    task.service.ts
  routes/ or pages/
    index.ts
  middleware/
    auth.ts
    error-handler.ts
    rate-limiter.ts
  database/
    connection.ts
    migrations/
  utils/
    validators.ts
    formatters.ts
tests/
  setup.ts                   # Test config
  user.service.test.ts
  task.service.test.ts
.env.example
package.json
tsconfig.json
README.md
```

## Config Pattern — Fail Fast on Missing Env Vars

```python
# config.py — Python
import os
import sys

class Config:
    """Application configuration. Fails fast if required vars are missing."""
    
    def __init__(self):
        self.TELEGRAM_BOT_TOKEN = self._require("TELEGRAM_BOT_TOKEN")
        self.DATABASE_URL = self._require("DATABASE_URL")
        self.LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
        self.MAX_RETRIES = int(os.getenv("MAX_RETRIES", "3"))
    
    def _require(self, key: str) -> str:
        value = os.getenv(key)
        if not value:
            print(f"FATAL: Required environment variable '{key}' is not set.", file=sys.stderr)
            print(f"Copy .env.example to .env and fill in all required values.", file=sys.stderr)
            sys.exit(1)
        return value

config = Config()
```

```typescript
// config.ts — TypeScript
function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    console.error(`FATAL: Required environment variable '${key}' is not set.`);
    console.error('Copy .env.example to .env and fill in all required values.');
    process.exit(1);
  }
  return value;
}

export const config = {
  telegramToken: requireEnv('TELEGRAM_BOT_TOKEN'),
  databaseUrl: requireEnv('DATABASE_URL'),
  logLevel: process.env.LOG_LEVEL ?? 'info',
  maxRetries: parseInt(process.env.MAX_RETRIES ?? '3', 10),
} as const;
```

## Common Anti-Patterns to AVOID

| Anti-Pattern | Why It's Bad | What to Do Instead |
|---|---|---|
| `catch(e) {}` / `except: pass` | Silently swallows errors, makes debugging impossible | Catch specific exceptions, log with context |
| `SELECT *` | Over-fetches data, breaks when schema changes | Select only needed columns |
| Storing passwords in plaintext | Catastrophic security breach | Use bcrypt/argon2 with salt |
| Sequential await in loops | Turns parallel work into O(n) serial | Use `Promise.all()` or `asyncio.gather()` |
| String concatenation for SQL | SQL injection vulnerability | Use parameterized queries |
| `any` type in TypeScript | Defeats the purpose of TypeScript | Define proper interfaces |
| Returning `null` for errors | Caller forgets to check, NPE later | Throw typed exceptions |
| Global mutable state | Race conditions, untestable code | Dependency injection |

## When Fixing Bugs

1. Read the ENTIRE bug report first — understand the full picture
2. Reproduce the bug mentally by tracing through the code
3. Identify the **root cause** — not just the symptom
4. Make the **minimum focused change** that fixes the root cause
5. Check for the same bug pattern elsewhere in the codebase
6. Do NOT refactor, optimize, or "improve" adjacent code
7. Document in `fix-log.md` with root cause analysis
