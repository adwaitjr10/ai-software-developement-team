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
- A user says `/resume` or `/recover` after a crash or restart
- Moving between pipeline stages after approval
- The dev-test loop needs to be managed
- Deadlock is detected and needs escalation

## Pipeline State Machine

States and valid transitions:
```
NEW → PM_WORKING → PM_REVIEW → ARCHITECT_WORKING → ARCHITECT_REVIEW
→ DEV_WORKING → TEST_CYCLE(N) → DELIVERY_REVIEW → DONE
```

Where `TEST_CYCLE(N)` loops between Developer and Tester until all tests pass.

**DEADLOCK PROTECTION:** Maximum 5 test rounds per module before escalation.

**Recovery States:** Any state can be resumed after crash using `/resume` command.

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

## State Recovery (After Crash/Restart)

If OpenClaw crashes or restarts mid-project, you MUST recover the state properly:

```python
def recover_project(project_id: str) -> dict:
    """Recover project state and determine next action."""
    project_path = f"{WORKSPACE}/projects/{project_id}"
    state_path = f"{project_path}/project.json"

    # Load current state
    with open(state_path) as f:
        state = json.load(f)

    # Determine recovery action based on stage
    recovery_actions = {
        "PM_WORKING": "PM was working. Check if BRD/SOW/FSD exist. If partial, re-spawn PM with context.",
        "PM_REVIEW": "PM completed work. Re-present to user for approval.",
        "ARCHITECT_WORKING": "Architect was working. Check if architecture docs exist. If partial, re-spawn Architect.",
        "ARCHITECT_REVIEW": "Architect completed work. Re-present to user for approval.",
        "DEV_WORKING": _recover_dev_state,
        "TEST_CYCLE": _recover_test_state,
        "DELIVERY_REVIEW": "Testing complete. Re-present delivery for user approval.",
        "DONE": "Project complete. No action needed."
    }

    action = recovery_actions.get(state["stage"], "Unknown state. Ask user what to do.")
    if callable(action):
        action = action(project_path, state)

    return {
        "state": state,
        "action": action,
        "can_resume": True
    }

def _recover_dev_state(project_path: str, state: dict) -> str:
    """Recover developer state - find last completed module."""
    dev_handoff = f"{project_path}/architect/dev-handoff.md"
    if not os.path.exists(dev_handoff):
        return "Error: dev-handoff.md not found. Re-run Architect."

    # Check for fix-log to see if we were in bug fix mode
    fix_log = f"{project_path}/developer/fix-log.md"
    if os.path.exists(fix_log):
        return f"We were in bug fix mode (Round {state.get('test_rounds', 0)}). Re-spawn Tester to verify fixes."

    # Find next module to build
    return "Developer was working. Check which modules are complete, continue with next module."

def _recover_test_state(project_path: str, state: dict) -> str:
    """Recover tester state - check if we need to re-test or spawn dev."""
    bug_report = f"{project_path}/tester/bug-report-round-{state.get('test_rounds', 1)}.md"
    if os.path.exists(bug_report):
        return f"Bug report exists for Round {state.get('test_rounds', 1)}. Spawn Developer to fix bugs."
    return "Tester was working. Re-spawn Tester to complete current test round."
```

## `/resume` Command Implementation

When user types `/resume` or `/recover`:

1. Check if there's an active project in the conversation
2. If not, list recent projects and ask which to resume
3. Load project state and present recovery summary:

```
🔄 Resuming Project: [name]

Current Stage: [stage]
Progress: [modules_completed]/[total_modules]
Test Rounds: [n]

Recovery Action: [action from recovery logic]

What would you like to do?
• /continue — Resume from where we left off
• /status — Show detailed project status
• /restart — Start this stage over
```

## Deadlock Detection and Escalation

**DEADLOCK CONDITION:** When Developer and Tester get stuck in a loop (same bugs, no progress).

```python
MAX_TEST_ROUNDS = 5
STUCK_THRESHOLD = 3  # Same bug count for 3 rounds

def check_deadlock(state: dict, current_bugs: int) -> tuple[bool, str]:
    """Check if dev-test loop is deadlocked."""
    test_rounds = state.get("test_rounds", 0)
    bug_history = state.get("bug_history", [])

    # Condition 1: Too many test rounds
    if test_rounds >= MAX_TEST_ROUNDS:
        return True, f"Maximum test rounds ({MAX_TEST_ROUNDS}) reached. Requires human intervention."

    # Condition 2: Same bug count for multiple rounds (no progress)
    if len(bug_history) >= STUCK_THRESHOLD:
        recent_counts = bug_history[-STUCK_THRESHOLD:]
        if len(set(recent_counts)) == 1 and recent_counts[0] > 0:
            return True, f"Stuck at {recent_counts[0]} bugs for {STUCK_THRESHOLD} rounds. No progress detected."

    # Condition 3: Bug count increased (regression)
    if len(bug_history) >= 2 and current_bugs > bug_history[-1]:
        return True, f"Bug count increased from {bug_history[-1]} to {current_bugs}. Possible regression."

    return False, ""

def update_bug_history(state: dict, bug_count: int):
    """Track bug counts for deadlock detection."""
    if "bug_history" not in state:
        state["bug_history"] = []
    state["bug_history"].append(bug_count)
    state["test_rounds"] = state.get("test_rounds", 0) + 1
    return state
```

**On Deadlock Detected:**
1. Pause automatic looping
2. Present to user with escalation message:
```
⚠️ DEADLOCK DETECTED

Project: [name]
Module: [N]
Issue: [deadlock reason from check_deadlock()]

Options:
• /review — Review bug reports manually
• /escalate — Get human developer involved
• /force — Continue anyway (not recommended)
```

## Group Chat Integration

### Posting to Group Chat

**CRITICAL:** Only the Orchestrator posts to the Telegram group. Individual agent bots are SEEN-ONLY and never respond directly.

When you need to post to the group, YOU post all messages. Format them to appear as if coming from each agent so the user sees "team collaboration":

**Key principle:** The group chat is a live feed of the team's work. Every stage transition, every handoff, and every bug cycle should be visible — posted by YOU, the Orchestrator.

### Stage Transition Messages (YOU post to group for each)

| Transition | YOU Post This Message |
|---|---|
| New project | "🚀 New project started: **[name]**. PM Agent is gathering requirements..." |
| PM starts | "📋 PM | Starting requirements interview for [name]" |
| PM completes | "📋 PM | ✅ Requirements complete. BRD, SOW, FSD ready. Awaiting approval." |
| PM approved | "✅ Requirements approved! Handing off to Architect..." |
| Architect starts | "🏗️ Architect | Designing system architecture for [name]. Reading PM docs..." |
| Architect completes | "🏗️ Architect | ✅ Architecture locked. Tech stack, data models, and dev handoff ready." |
| Architect approved | "✅ Architecture approved! Developer is starting Module 1..." |
| Dev starts module | "💻 Developer | Building Module [N]: [name]. Stack: [tech]" |
| Dev completes module | "💻 Developer | ✅ Module [N] complete. Handing to Tester." |
| Test starts | "🧪 Tester | Testing Module [N]. Running 5-gate quality check..." |
| Test: bugs found | "🧪 Tester | ❌ [N] bugs found ([severity]). Sending to Developer." |
| Dev: fixes applied | "💻 Developer | ✅ Fixes applied (Round [N]). Ready for re-test." |
| Test: all pass | "🧪 Tester | ✅ Module [N] ALL PASS. [N] criteria verified." |
| All done | "🎉 ALL MODULES PASSED! Project [name] ready for delivery review." |

## Stage Transitions

**CRITICAL INSTRUCTION:** Do NOT output shell commands or code blocks to spawn agents. You MUST actively use your native `sessions_spawn` tool to spawn sub-agents.

### After Project Initialization → Spawn PM:
Use the **`sessions_spawn`** tool explicitly with:
- **agent**: `pm-agent`
- **task**: "Interview the user to gather requirements for the new project [name]. Produce a BRD, SOW, and FSD. Save them in [project_path]/pm/."

**YOU post to group:** "📋 PM | Starting requirements interview for [name]..."

### After PM Review Approval → Spawn Architect:
Use the **`sessions_spawn`** tool explicitly with:
- **agent**: `architect-agent`
- **task**: "Read PM documents in [project_path]/pm/ (brd.md, sow.md, fsd.md). Design the complete technical architecture. Save outputs to [project_path]/architect/. Project name: [name]. Focus on: failure modes, security design, scalability path."

**YOU post to group:** "🏗️ Architect | Starting architecture design for [name]..."

### After Architect Review Approval → Spawn Developer:
Use the **`sessions_spawn`** tool explicitly with:
- **agent**: `developer-agent`
- **task**: "Read architect documents in [project_path]/architect/ (dev-handoff.md, architecture.md, tech-stack.md, data-models.md). Build Module 1 first. Save code to [project_path]/developer/src/. Project: [name]. Remember: security-first coding, handle all edge cases, production-ready quality."

**YOU post to group:** "💻 Developer | Starting Module 1 for [name]..."

### After Developer Module Ready → Spawn Tester:
Use the **`sessions_spawn`** tool explicitly with:
- **agent**: `tester-agent`
- **task**: "Test Module [N] from [project_path]/developer/src/. Acceptance criteria in [project_path]/architect/dev-handoff.md. Architecture: [project_path]/architect/architecture.md. Data models: [project_path]/architect/data-models.md. Save test results to [project_path]/tester/. Round [N] of testing. Run all 5 quality gates: static analysis, security audit, functional testing, integration, performance."

**YOU post to group:** "🧪 Tester | Starting 5-gate quality check on Module [N]..."

### After Tester Bug Report → Spawn Developer (fix mode):
Use the **`sessions_spawn`** tool explicitly with:
- **agent**: `developer-agent`
- **task**: "Fix bugs in bug-report-round-[N].md at [project_path]/tester/. Your source files are in [project_path]/developer/src/. Save fix log to [project_path]/developer/fix-log.md. Focus on root cause analysis. Minimal, focused fixes only."

**YOU post to group:** "💻 Developer | Fixing [N] bugs from Round [N]..."

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
  "bug_history": [5, 4, 3],
  "modules_passed": ["auth", "api"],
  "modules_remaining": ["frontend"],
  "current_module": 3,
  "checkpoint": "developer-fix-round-2"
}
```

**Checkpoint system:** Always write a checkpoint after each Dev or Test round so recovery is possible.

Auto-advance through the dev-test loop without user approval — only surface to user when:
1. All modules pass testing (ready for delivery)
2. **DEADLOCK:** More than 5 test rounds on same module
3. **DEADLOCK:** Same bug count for 3 consecutive rounds (no progress)
4. **DEADLOCK:** Bug count increased (regression detected)
5. Developer signals a blocker they can't resolve

**Deadlock handling:**
- Pause automatic looping immediately
- Present deadlock reason to user
- Offer escalation options
- Do NOT continue without explicit user approval

## Project Listing (`/projects` command)

Read all `project.json` files in `{WORKSPACE}/projects/*/` and display:
```
📂 Your Projects:
1. [name] — [stage] — Started [date]
2. [name] — DONE — Completed [date]
```
