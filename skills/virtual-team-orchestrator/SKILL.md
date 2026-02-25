---
name: virtual-team-orchestrator
description: Manages the 4-agent virtual software team pipeline with Telegram group chat collaboration. Use when starting a new project, checking pipeline status, or routing work between PM → Architect → Developer → Tester agents with approval gates.
metadata:
  openclaw:
    requires:
      bins:
        - python3
---

# Virtual Team Orchestrator Skill

This skill guides the Orchestrator in managing the full software development pipeline with visible Telegram group chat collaboration.

## When to Use This Skill

Activate this skill when:
- A user says `/new`, "build me a", "I want to create", "let's start a project"
- A user says `/status` or asks about pipeline progress
- Moving between pipeline stages after approval
- The dev-test loop needs to be managed

## Pipeline State Machine

States and valid transitions:
```
NEW → PM_WORKING → PM_REVIEW → ARCHITECT_WORKING → ARCHITECT_REVIEW 
→ DEV_WORKING → TEST_CYCLE(N) → DELIVERY_REVIEW → DONE
```

Where `TEST_CYCLE(N)` loops between Developer and Tester until all tests pass.

## Project Initialization

When starting a new project:

```python
import json, os, time
from pathlib import Path

project_id = f"proj-{int(time.time())}"
project_path = f"{WORKSPACE}/projects/{project_id}"
os.makedirs(f"{project_path}/pm", exist_ok=True)
os.makedirs(f"{project_path}/architect", exist_ok=True)
os.makedirs(f"{project_path}/developer/src", exist_ok=True)
os.makedirs(f"{project_path}/tester", exist_ok=True)

state = {
    "id": project_id,
    "name": "TBD",
    "stage": "PM_WORKING",
    "created": time.time(),
    "approvals": [],
    "test_rounds": 0,
    "path": project_path
}
with open(f"{project_path}/project.json", "w") as f:
    json.dump(state, f, indent=2)
```

## Group Chat Integration

### Posting to Group Chat

When the FORGE Orchestrator or any agent needs to post to the Telegram group, the orchestrator coordinates this. Each agent's output should be posted using that agent's channel so it appears as that bot in the group:

**Key principle:** The group chat is a live feed of the team's work. Every stage transition, every handoff, and every bug cycle should be visible.

### Stage Transition Messages (post to group for each)

| Transition | Channel | Message |
|---|---|---|
| New project | forge | "🚀 New project started: **[name]**. PM Agent is gathering requirements..." |
| PM starts | pm | "📋 PM | Starting requirements interview for [name]" |
| PM completes | pm | "📋 PM | ✅ Requirements complete. BRD, SOW, FSD ready. Awaiting approval." |
| PM approved | forge | "✅ Requirements approved! Handing off to Architect..." |
| Architect starts | architect | "🏗️ Architect | Designing system architecture for [name]. Reading PM docs..." |
| Architect completes | architect | "🏗️ Architect | ✅ Architecture locked. Tech stack, data models, and dev handoff ready." |
| Architect approved | forge | "✅ Architecture approved! Developer is starting Module 1..." |
| Dev starts module | developer | "💻 Developer | Building Module [N]: [name]. Stack: [tech]" |
| Dev completes module | developer | "💻 Developer | ✅ Module [N] complete. Handing to Tester." |
| Test starts | tester | "🧪 Tester | Testing Module [N]. Running 5-gate quality check..." |
| Test: bugs found | tester | "🧪 Tester | ❌ [N] bugs found ([severity]). Sending to Developer." |
| Dev: fixes applied | developer | "💻 Developer | ✅ Fixes applied (Round [N]). Ready for re-test." |
| Test: all pass | tester | "🧪 Tester | ✅ Module [N] ALL PASS. [N] criteria verified." |
| All done | forge | "🎉 ALL MODULES PASSED! Project [name] ready for delivery review." |

## Stage Transitions

### After PM Review Approval → Spawn Architect:
```
sessions_spawn --agent architect-agent \
  --task "Read PM documents in [project_path]/pm/ (brd.md, sow.md, fsd.md). 
          Design the complete technical architecture. 
          Save outputs to [project_path]/architect/. 
          Project name: [name].
          Focus on: failure modes, security design, scalability path."
```
Post to group (architect channel): "🏗️ Architect | Starting architecture design for [name]..."

### After Architect Review Approval → Spawn Developer:
```
sessions_spawn --agent developer-agent \
  --task "Read architect documents in [project_path]/architect/ 
          (dev-handoff.md, architecture.md, tech-stack.md, data-models.md).
          Build Module 1 first. Save code to [project_path]/developer/src/.
          Project: [name].
          Remember: security-first coding, handle all edge cases, production-ready quality."
```
Post to group (developer channel): "💻 Developer | Starting Module 1 for [name]..."

### After Developer Module Ready → Spawn Tester:
```
sessions_spawn --agent tester-agent \
  --task "Test Module [N] from [project_path]/developer/src/.
          Acceptance criteria in [project_path]/architect/dev-handoff.md.
          Architecture: [project_path]/architect/architecture.md.
          Data models: [project_path]/architect/data-models.md.
          Save test results to [project_path]/tester/.
          Round [N] of testing.
          Run all 5 quality gates: static analysis, security audit, functional testing, integration, performance."
```
Post to group (tester channel): "🧪 Tester | Starting 5-gate quality check on Module [N]..."

### After Tester Bug Report → Spawn Developer (fix mode):
```
sessions_spawn --agent developer-agent \
  --task "Fix bugs in bug-report-round-[N].md at [project_path]/tester/.
          Your source files are in [project_path]/developer/src/.
          Save fix log to [project_path]/developer/fix-log.md.
          Focus on root cause analysis. Minimal, focused fixes only."
```
Post to group (developer channel): "💻 Developer | Fixing [N] bugs from Round [N]..."

## Approval Message Format

Always send approval gates in this exact format:

```
📋 *[STAGE] Complete*

Project: [name]
Stage: [current] → [next]

[2-3 sentence summary]

⭐ Quality highlights:
• [Notable aspect of the work]

📁 Key outputs:
• [file 1]
• [file 2]

Reply with:
✅ /approve — proceed to [next stage]
🔄 /changes [feedback] — request revisions  
❌ /reject [reason] — stop and discuss
```

Then wait for user response before spawning the next agent.

## Dev-Test Loop Tracking

Track test rounds in project.json:
```json
{
  "test_rounds": 2,
  "last_bug_count": 3,
  "modules_passed": ["auth", "api"],
  "modules_remaining": ["frontend"]
}
```

Auto-advance through the dev-test loop without user approval — only surface to user when:
1. All modules pass testing (ready for delivery)
2. More than 5 test rounds on same module (flag for human review)
3. Developer signals a blocker they can't resolve

## Project Listing (`/projects` command)

Read all `project.json` files in `{WORKSPACE}/projects/*/` and display:
```
📂 Your Projects:
1. [name] — [stage] — Started [date]
2. [name] — DONE — Completed [date]
```
