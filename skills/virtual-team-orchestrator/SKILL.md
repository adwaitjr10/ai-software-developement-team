---
name: virtual-team-orchestrator
description: Manages the 4-agent virtual software team pipeline. Use when starting a new project, checking pipeline status, or routing work between PM → Architect → Developer → Tester agents with approval gates.
metadata:
  openclaw:
    requires:
      bins:
        - python3
---

# Virtual Team Orchestrator Skill

This skill guides the Orchestrator in managing the full software development pipeline.

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
→ DEV_WORKING → TEST_CYCLE(N) → DONE
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

## Stage Transitions

### After PM Review Approval → Spawn Architect:
```
sessions_spawn --agent architect-agent \
  --task "Read PM documents in [project_path]/pm/ (brd.md, sow.md, fsd.md). 
          Design the complete technical architecture. 
          Save outputs to [project_path]/architect/. 
          Project name: [name]."
```

### After Architect Review Approval → Spawn Developer:
```
sessions_spawn --agent developer-agent \
  --task "Read architect documents in [project_path]/architect/ 
          (dev-handoff.md, architecture.md, tech-stack.md, data-models.md).
          Build Module 1 first. Save code to [project_path]/developer/src/.
          Project: [name]."
```

### After Developer Module Ready → Spawn Tester:
```
sessions_spawn --agent tester-agent \
  --task "Test Module [N] from [project_path]/developer/src/.
          Acceptance criteria in [project_path]/architect/dev-handoff.md.
          Save test results to [project_path]/tester/.
          Round [N] of testing."
```

### After Tester Bug Report → Spawn Developer (fix mode):
```
sessions_spawn --agent developer-agent \
  --task "Fix bugs in bug-report-round-[N].md at [project_path]/tester/.
          Your source files are in [project_path]/developer/src/.
          Save fix log to [project_path]/developer/fix-log.md."
```

## Approval Message Format

Always send approval gates in this exact format:

```
📋 *[STAGE] Complete*

Project: [name]
Stage: [current] → [next]

[2-3 sentence summary]

📁 Key outputs:
• [file 1]
• [file 2]

Reply with:
✅ /approve — proceed to [next stage]
🔄 /changes [feedback] — request revisions  
❌ /reject [reason] — stop and discuss
```

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
