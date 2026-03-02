# FORGE Meeting Bot

Real-time voice meeting facilitator for the FORGE virtual software team.

## What It Does

- Joins Telegram Voice Chats
- Transcribes speech in real-time using OpenAI Whisper
- Feeds transcript to PM Agent for analysis
- Sends PM Agent's questions as Text Messages back to the group chat
- After meeting: Auto-generates BRD/SOW/FSD

## 100% Free & Open Source

| Component | License | Cost |
|-----------|---------|------|
| Whisper | MIT | ✅ Free |
| pyTelegramBotAPI | GPL-2.0 | ✅ Free |
| Python + libraries | Various OSS | ✅ Free |
| Telegram Voice Chat | Telegram API | ✅ Free |

## Installation

### 1. Install System Dependencies

```bash
# macOS
brew install ffmpeg portaudio

# Ubuntu/Debian
sudo apt-get install ffmpeg portaudio19-dev python3-pyaudio

# Arch
sudo pacman -S ffmpeg portaudio python-pyaudio
```

### 2. Install Python Dependencies

```bash
cd meeting-bot
pip install -r requirements.txt
```

### 3. Download Whisper Model (first run only)

```bash
# Whisper will auto-download the model on first run
# Or manually download for faster startup:
python -c "import whisper; whisper.load_model('base')"
```

## Usage

### As a Standalone Script

```bash
python meeting_bot.py --project proj-123 --meeting mtg-456 --telegram-token YOUR_BOT_TOKEN --chat-id YOUR_GROUP_CHAT_ID
```

### From the FORGE Orchestrator

When a user types `/meeting` in Telegram:

```python
# Orchestrator spawns the meeting bot
sessions_spawn(
    agent="meeting-bot",
    task="Start a meeting for project [name]. Join voice chat and transcribe..."
)
```

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Voice Meeting Flow                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Client speaks → Audio captured → Whisper transcribes       │
│                                      ↓                      │
│                              Transcript accumulated          │
│                                      ↓                      │
│                              Every 30 seconds:              │
│                                      ↓                      │
│                              Send to PM Agent               │
│                                      ↓                      │
│                              PM Agent analyzes               │
│                                      ↓                      │
│                              Questions generated             │
│                                      ↓                      │
│                              Sent to Group via Telegram API  │
│                                      ↓                      │
│                              Client responds → repeat        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Meeting Output Files

After a meeting, the following files are created:

```
~/.openclaw/workspace/projects/{project_id}/meetings/
├── meeting.json          # Full meeting state
├── transcript.txt        # Human-readable transcript
├── summary.md            # Summary for PM Agent
└── recording.wav         # Full audio recording
```

## Integration with FORGE Pipeline

The meeting bot integrates seamlessly:

```
User: /meeting
   ↓
Meeting Bot joins voice chat
   ↓
[Transcribes and facilitates]
   ↓
Meeting ends
   ↓
PM Agent receives transcript
   ↓
BRD/SOW/FSD generated
   ↓
Continue: Architect → Developer → Tester
```

## Commands

| Command | Description |
|---------|-------------|
| `/meeting` | Start a new meeting |
| `/meeting end` | End current meeting |
| `/meeting status` | Show meeting status |

## Technical Specs

- **Audio Sample Rate:** 16kHz (Whisper optimal)
- **Channels:** Mono
- **Chunk Duration:** 30 seconds
- **Max Meeting Duration:** 1 hour
- **Whisper Model:** `base` (74MB, ~1GB VRAM)
- **Output:** Text messages via Telegram API

## Privacy

- Transcripts stored locally only
- No cloud API calls for transcription
- Encrypted at rest (when enabled)
- Client consent always obtained

## Troubleshooting

**Whisper fails to load:**
```bash
pip install --upgrade openai-whisper
```

**pyTelegramBotAPI not working:**
```bash
pip install pyTelegramBotAPI
# Provide --telegram-token and --chat-id when running
```

**Audio device issues:**
```bash
# List available audio devices
python -c "import pyaudio; p = pyaudio.PyAudio(); [print(i, p.get_device_info_by_index(i)['name']) for i in range(p.get_device_count())]"
```

## Future Enhancements

- [ ] Native Telegram Voice Chat integration (waiting for API support)
- [ ] Speaker diarization (who is speaking)
- [ ] Real-time emotion detection
- [ ] Multi-language support
- [ ] Meeting recording playback
