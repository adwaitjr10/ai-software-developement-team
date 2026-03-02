---
name: meeting-mode
description: Real-time voice meeting mode for PM Agent. Joins Telegram Voice Chats, transcribes, facilitates PM questions, and auto-generates BRD. Use when user says /meeting, /call, or requests a voice meeting.
metadata:
  openclaw:
    requires:
      bins:
        - python3
        - ffmpeg
---

# Meeting Mode Skill

## When to Use This Skill

Activate this skill when:
- User says `/meeting` or `/call`
- User says "let's have a call" or "schedule a meeting"
- User says "can we talk?" or "voice meeting"
- PM needs to clarify requirements verbally
- User prefers speaking over typing

## Meeting Mode Flow

```
User: /meeting
   ↓
Orchestrator creates Telegram Voice Chat
   ↓
Orchestrator spawns Meeting Bot as sub-agent
   ↓
Meeting Bot joins voice chat
   ↓
[REAL-TIME LOOP]
   ├─ Meeting Bot listens and transcribes (Whisper)
   ├─ Every 30s → send transcript to PM Agent
   ├─ PM Agent analyzes → generates questions
   ├─ Meeting Bot speaks questions (TTS)
   └─ Client responds → repeat
   ↓
Meeting ends (user leaves or timeout)
   ↓
Meeting Bot sends full transcript to PM Agent
   ↓
PM Agent generates BRD, SOW, FSD
   ↓
Continue normal pipeline (Architect → Developer → Tester)
```

## /meeting Command Implementation

When user types `/meeting`:

```python
def start_meeting_mode(user_id: str, project_id: str = None):
    """Start a real-time voice meeting with the PM Agent."""

    # Create project if needed
    if not project_id:
        project_id = f"meeting-{int(time.time())}"
        project_path = f"{WORKSPACE}/projects/{project_id}"
        os.makedirs(f"{project_path}/pm", exist_ok=True)
        os.makedirs(f"{project_path}/meetings", exist_ok=True)

    # Start meeting
    meeting_data = {
        "id": f"mtg-{int(time.time())}",
        "project_id": project_id,
        "started_by": user_id,
        "started_at": time.time(),
        "status": "waiting",
        "transcript": [],
        "recording_path": f"{project_path}/meetings/meeting-{int(time.time())}.wav"
    }

    # Create voice chat
    voice_chat_link = create_telegram_voice_chat()

    # Spawn Meeting Bot
    sessions_spawn(
        agent="meeting-bot",
        task=f"""
Join the voice chat at {voice_chat_link} and facilitate the meeting:

1. Introduce yourself as the AI meeting facilitator
2. Start transcribing with Whisper
3. Every 30 seconds, send transcript to PM Agent for analysis
4. If PM Agent has questions, speak them via TTS
5. Listen for client responses
6. Continue until meeting ends
7. After meeting: send full transcript to PM Agent for BRD generation

Project ID: {project_id}
Meeting ID: {meeting_data['id']}
"""
    )

    # Post to group
    post_to_group(f"""
🎙️ **Meeting Mode Activated**

Project: {project_id}
Voice Chat: {voice_chat_link}

The Meeting Bot has joined. Start speaking whenever you're ready!

I'll be transcribing our conversation and the PM Agent will ask questions along the way.
""")
```

## Meeting State Tracking

Track meetings in `{project_path}/meetings/meeting.json`:

```json
{
  "id": "mtg-1234567890",
  "project_id": "proj-1234567890",
  "status": "active|completed|cancelled",
  "started_at": 1234567890,
  "ended_at": null,
  "duration_seconds": 0,
  "participants": ["client_name", "pm_agent"],
  "transcript": [
    {"timestamp": 0.5, "speaker": "client", "text": "Hi, I'd like to build a..."},
    {"timestamp": 5.2, "speaker": "meeting_bot", "text": "Great! Can you tell me more about..."}
  ],
  "pm_questions_asked": [
    {"timestamp": 30.5, "question": "Who are the target users?", "answer": "..."}
  ],
  "recording_path": "/path/to/recording.wav"
}
```

## After Meeting: Handoff to PM Agent

When meeting ends, spawn PM Agent with transcript:

```python
sessions_spawn(
    agent="pm-agent",
    task=f"""
You have just completed a voice meeting with the client.

## Meeting Transcript
{full_transcript}

## Meeting Summary
- Duration: {duration} minutes
- Client: {client_name}
- Date: {date}

## Your Task
Analyze the meeting transcript and create:
1. **BRD** (Business Requirements Document) - What problem are we solving?
2. **SOW** (Statement of Work) - Scope, timeline, deliverables
3. **FSD** (Functional Specification Document) - Features with Given/When/Then criteria

Save to: {project_path}/pm/

## Key Points Already Identified
{key_points_from_meeting}

## Gaps to Fill
If the meeting didn't cover everything in your standard interview, note what's missing and flag for follow-up.
"""
)
```

## Meeting Commands

| Command | Description |
|---------|-------------|
| `/meeting` | Start a new voice meeting |
| `/meeting end` | End current meeting |
| `/meeting pause` | Pause transcription |
| `/meeting resume` | Resume transcription |
| `/meeting status` | Show current meeting status |

## Integration with Existing Pipeline

Meeting mode integrates seamlessly with the existing FORGE pipeline:

```
NORMAL PIPELINE:
User → Orchestrator → PM Agent (text interview) → BRD/SOW/FSD → Architect...

MEETING MODE:
User → /meeting → Voice Chat → Meeting Bot → PM Agent (voice interview) → BRD/SOW/FSD → Architect...

After BRD is generated, both paths merge and continue identically.
```

## Error Handling

### Client Doesn't Show Up
- Wait 5 minutes, then send: "Meeting starting in 1 minute. Join now or we can reschedule."
- After 10 minutes: Auto-cancel and offer to schedule via text

### Transcription Fails
- Fall back to text-based PM interview
- Notify client: "Having audio issues. Switching to text chat."

### TTS Fails
- Send PM questions as text messages instead
- Continue meeting in chat

## Meeting Bot Technical Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| **Transcription** | OpenAI Whisper (local) | Speech-to-text |
| **TTS** | Piper TTS (local) | Text-to-speech |
| **Audio I/O** | ffmpeg | Audio capture/playback |
| **Telegram Audio** | pyTGP (fork) | Voice chat streaming |
| **PM Agent** | Existing pm-agent | Interview logic |

## Free & Open Source

Everything is 100% free and open-source:
- Whisper: MIT license
- Piper TTS: MIT license
- ffmpeg: GPL/LGPL
- Python libraries: Various open-source licenses

No API calls to paid services. Everything runs locally.
