---
name: project-state
description: Read and update project pipeline state. Use to get current project stage, save approvals, update test round counts, or retrieve project context for sub-agents.
metadata:
  openclaw:
    requires:
      bins:
        - python3
---

# Project State Skill

This skill manages `project.json` state files for each active project.

## State File Schema

Location: `{WORKSPACE}/projects/{project-id}/project.json`

```json
{
  "id": "proj-1234567890",
  "name": "Telegram Todo Bot",
  "stage": "ARCHITECT_REVIEW",
  "created": 1708876543.0,
  "path": "/path/to/workspace/projects/proj-1234567890",
  "description": "A Telegram bot that manages tasks with reminders",
  "approvals": [
    {
      "stage": "PM_REVIEW",
      "approved_at": 1708876600.0,
      "feedback": null
    }
  ],
  "test_rounds": 0,
  "last_bug_count": 0,
  "modules_passed": [],
  "modules_remaining": [],
  "changes_requested": []
}
```

## Python Helper — Read/Write State

```python
import json
from pathlib import Path

WORKSPACE = "{baseDir}/../.."  # adjust to your workspace path

def get_project(project_id: str) -> dict:
    path = Path(WORKSPACE) / "projects" / project_id / "project.json"
    return json.loads(path.read_text())

def update_project(project_id: str, updates: dict) -> dict:
    path = Path(WORKSPACE) / "projects" / project_id / "project.json"
    state = json.loads(path.read_text())
    state.update(updates)
    path.write_text(json.dumps(state, indent=2))
    return state

def list_projects() -> list[dict]:
    projects_dir = Path(WORKSPACE) / "projects"
    results = []
    for p in projects_dir.glob("*/project.json"):
        results.append(json.loads(p.read_text()))
    return sorted(results, key=lambda x: x["created"], reverse=True)

def approve_stage(project_id: str, stage: str, feedback: str = None):
    import time
    state = get_project(project_id)
    state["approvals"].append({
        "stage": stage,
        "approved_at": time.time(),
        "feedback": feedback
    })
    update_project(project_id, {"approvals": state["approvals"]})

def request_changes(project_id: str, stage: str, feedback: str):
    import time
    state = get_project(project_id)
    state.setdefault("changes_requested", []).append({
        "stage": stage,
        "requested_at": time.time(),
        "feedback": feedback
    })
    update_project(project_id, {"changes_requested": state["changes_requested"]})
```

## Stage Constants

Valid stages in order:
1. `NEW` — just created
2. `PM_WORKING` — PM agent running
3. `PM_REVIEW` — waiting for user approval of PM docs
4. `ARCHITECT_WORKING` — architect agent running
5. `ARCHITECT_REVIEW` — waiting for user approval of architecture
6. `DEV_WORKING` — developer building current module
7. `TEST_CYCLE` — tester running (auto-loops with dev)
8. `DELIVERY_REVIEW` — waiting for final user approval
9. `DONE` — project complete

## Usage Examples

**Get current project state:**
Use `get_project(project_id)` then read the `stage` field.

**After user approves PM docs:**
```python
approve_stage(project_id, "PM_REVIEW")
update_project(project_id, {"stage": "ARCHITECT_WORKING"})
```

**After user requests changes:**
```python
request_changes(project_id, "PM_REVIEW", "Please add more detail on the API design")
update_project(project_id, {"stage": "PM_WORKING"})
# Then re-spawn PM agent with the feedback
```

**Track test rounds:**
```python
state = get_project(project_id)
update_project(project_id, {
    "test_rounds": state["test_rounds"] + 1,
    "last_bug_count": 3
})
```
