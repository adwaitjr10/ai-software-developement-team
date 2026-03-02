#!/usr/bin/env python3
"""
FORGE Meeting Bot - Real-time Voice Meeting Facilitator

Joins Telegram Voice Chats, transcribes with Whisper, facilitates PM questions
with TTS, and generates BRD from meeting transcripts.

Requirements:
- pip install openai-whisper pyperclip piper-tts pytelegrambotapi
- brew install ffmpeg portaudio

Usage:
    python meeting_bot.py --project <project_id> --meeting <meeting_id>
"""

import os
import sys
import json
import time
import wave
import asyncio
import threading
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict
from typing import Optional, List, Dict
import subprocess

# Try importing openclaw API for integration
try:
    from openclaw.api import sessions_spawn
    OPENCLAW_AVAILABLE = True
except ImportError:
    OPENCLAW_AVAILABLE = False
    print("Warning: OpenClaw API not found. PM integration will be mocked.")

# Try importing optional dependencies
try:
    import whisper
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    print("Warning: Whisper not installed. Run: pip install openai-whisper")

try:
    import telebot
    from telebot.async_telebot import AsyncTeleBot
    TELEGRAM_AVAILABLE = True
except ImportError:
    TELEGRAM_AVAILABLE = False
    print("Warning: pyTelegramBotAPI not installed. Run: pip install pyTelegramBotAPI")

# ============== CONFIGURATION ==============

WORKSPACE = os.path.expanduser("~/.openclaw/workspace")
DEFAULT_SAMPLE_RATE = 16000
DEFAULT_CHANNELS = 1
CHUNK_DURATION = 30  # seconds
MAX_MEETING_DURATION = 3600  # 1 hour max

# ============== DATA CLASSES ==============

@dataclass
class MeetingSegment:
    """A single segment of the meeting transcript."""
    timestamp: float
    speaker: str  # "client" or "meeting_bot"
    text: str
    confidence: float = 1.0

@dataclass
class PMQuestion:
    """A question asked by the PM Agent during the meeting."""
    timestamp: float
    question: str
    answer: Optional[str] = None

@dataclass
class MeetingState:
    """The complete state of a meeting."""
    id: str
    project_id: str
    status: str  # "waiting", "active", "paused", "completed", "cancelled"
    started_at: float
    ended_at: Optional[float]
    duration_seconds: int
    participants: List[str]
    transcript: List[Dict]
    pm_questions: List[Dict]
    recording_path: str
    transcript_path: str

    def to_dict(self):
        return asdict(self)

    def save(self, path: str):
        """Save meeting state to JSON file."""
        with open(path, 'w') as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def load(cls, path: str):
        """Load meeting state from JSON file."""
        with open(path, 'r') as f:
            data = json.load(f)
        # Convert lists back to proper format
        data['transcript'] = [MeetingSegment(**t) if isinstance(t, dict) else t for t in data['transcript']]
        data['pm_questions'] = [PMQuestion(**q) if isinstance(q, dict) else q for q in data['pm_questions']]
        return cls(**data)

# ============== TRANSCRIPTION ENGINE ==============

class TranscriptionEngine:
    """Handles speech-to-text using OpenAI Whisper."""

    def __init__(self, model_size: str = "base"):
        if not WHISPER_AVAILABLE:
            raise RuntimeError("Whisper not installed. Run: pip install openai-whisper")

        print(f"Loading Whisper model: {model_size}...")
        self.model = whisper.load_model(model_size)
        self.model_size = model_size
        print(f"Whisper model loaded: {model_size}")

    def transcribe_file(self, audio_path: str) -> dict:
        """Transcribe an audio file."""
        result = self.model.transcribe(
            audio_path,
            language=None,  # Auto-detect
            word_timestamps=True,
            fp16=False  # Use FP32 for compatibility
        )
        return result

    def transcribe_chunk(self, audio_chunk: bytes) -> str:
        """Transcribe a real-time audio chunk."""
        # Save chunk to temp file
        temp_path = f"/tmp/whisper_chunk_{int(time.time() * 1000)}.wav"
        with wave.open(temp_path, 'wb') as wf:
            wf.setnchannels(DEFAULT_CHANNELS)
            wf.setsampwidth(2)  # 16-bit
            wf.setframerate(DEFAULT_SAMPLE_RATE)
            wf.writeframes(audio_chunk)

        try:
            result = self.model.transcribe(
                temp_path,
                language="en",
                fp16=False
            )
            return result["text"].strip()
        finally:
            os.remove(temp_path)

# ============== TELEGRAM ENGINE ==============

class TelegramEngine:
    """Handles sending text messages to an active Telegram Chat."""

    def __init__(self, token: str, chat_id: str):
        if not TELEGRAM_AVAILABLE and token and chat_id:
            print("Warning: Telegram libraries not available. Falling back to console-only mode.")
            self.available = False
            return
            
        self.available = False
        self.bot = None
        self.chat_id = chat_id
        
        if token and chat_id and TELEGRAM_AVAILABLE:
            try:
                self.bot = AsyncTeleBot(token)
                self.available = True
                print(f"Telegram engine ready for chat: {chat_id}")
            except Exception as e:
                print(f"Telegram initialization failed: {e}. Falling back to console-only mode.")

    async def speak(self, text: str) -> bool:
        """Send a message to the Telegram chat asynchronously."""
        if not self.available or not self.bot:
            return False

        try:
           await self.bot.send_message(self.chat_id, f"📝 **PM Question:**\n{text}", parse_mode="Markdown")
           return True
        except Exception as e:
           print(f"Failed to send Telegram message: {e}")
           return False

# ============== MEETING FACILITATOR ==============

class MeetingFacilitator:
    """Main meeting facilitation logic."""

    def __init__(self, project_id: str, meeting_id: str, workspace: str = WORKSPACE, demo: bool = False, telegram_token: str = None, chat_id: str = None):
        self.project_id = project_id
        self.meeting_id = meeting_id
        self.workspace = workspace
        self.demo = demo
        self.telegram_token = telegram_token
        self.chat_id = chat_id

        # Paths
        self.project_path = f"{workspace}/projects/{project_id}"
        self.meeting_path = f"{self.project_path}/meetings"
        self.state_path = f"{self.meeting_path}/meeting.json"
        self.recording_path = f"{self.meeting_path}/recording.wav"
        self.transcript_path = f"{self.meeting_path}/transcript.txt"

        # Ensure directories exist
        os.makedirs(self.meeting_path, exist_ok=True)

        # Load or create meeting state
        if os.path.exists(self.state_path):
            self.state = MeetingState.load(self.state_path)
        else:
            self.state = MeetingState(
                id=meeting_id,
                project_id=project_id,
                status="waiting",
                started_at=time.time(),
                ended_at=None,
                duration_seconds=0,
                participants=[],
                transcript=[],
                pm_questions=[],
                recording_path=self.recording_path,
                transcript_path=self.transcript_path
            )
            self.state.save(self.state_path)

        # Initialize engines
        self.transcriber = TranscriptionEngine(model_size="base") if WHISPER_AVAILABLE else None
        
        # In demo mode if whisper not available transcriber won't be used anyway
        if not WHISPER_AVAILABLE and self.demo:
            print("Running in DEMO mode without Whisper transcription engine.")
            
        self.telegram = TelegramEngine(self.telegram_token, self.chat_id)

    def start_meeting(self):
        """Start the meeting and begin facilitation."""
        print(f"\n🎙️ Meeting Started")
        print(f"Project: {self.project_id}")
        print(f"Meeting: {self.meeting_id}")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("-" * 50)

        self.state.status = "active"
        self.state.save(self.state_path)

        # Introduction
        intro = (
            "Hi! I'm the AI meeting facilitator for FORGE. "
            "I'll be transcribing our conversation and the PM Agent will ask questions along the way. "
            "Let's start whenever you're ready!"
        )
        print(f"\n🤖 Meeting Bot: {intro}")
        self._add_transcript_segment("meeting_bot", intro)
        
        async def run_initial_speak():
            await self.telegram.speak(intro)
            await self._meeting_loop()

        # Main meeting loop
        asyncio.run(run_initial_speak())

    async def _meeting_loop(self):
        """Main meeting loop - listen, transcribe, ask questions."""
        start_time = time.time()
        last_transcript_time = 0
        transcript_buffer = []

        while self.state.status == "active":
            current_time = time.time()
            elapsed = current_time - start_time

            # Check max duration
            if elapsed > MAX_MEETING_DURATION:
                print("\n⏰ Maximum meeting duration reached.")
                break

            # Every 30 seconds, process transcript and get PM questions
            if current_time - last_transcript_time > CHUNK_DURATION:
                if transcript_buffer:
                    chunk_text = " ".join(transcript_buffer)
                    print(f"\n📝 Transcript (last 30s):")
                    print(f"   {chunk_text[:200]}...")

                    # Get PM Agent questions
                    questions = await self._get_pm_questions(chunk_text, elapsed)

                    # Ask questions via Telegram
                    for question in questions:
                        print(f"\n🤖 PM Question: {question}")
                        await self.telegram.speak(question)
                        self._add_pm_question(question)

                        # Wait for response (simulate by getting more transcript)
                        await asyncio.sleep(5)

                    transcript_buffer = []
                last_transcript_time = current_time

            # Simulate listening (in real implementation, capture audio here)
            # Add something to buffer so it tests properly
            if self.demo:
                 transcript_buffer.append("Yes, user needs a fast dashboard. We want a timeline of 2 weeks. I like it to run in real time.")
            await asyncio.sleep(5)

        # End meeting
        await self.end_meeting()

    async def _get_pm_questions(self, transcript: str, elapsed: int) -> List[str]:
        """Send transcript to PM Agent and get questions."""
        questions = []
        
        if self.demo:
            # Simple keyword-based question generation (demo)
            if "user" in transcript.lower() and "need" in transcript.lower():
                questions.append("Can you tell me more about who will be using this product?")
    
            if "want" in transcript.lower() or "like" in transcript.lower():
                questions.append("What problem does this solve for your users?")
    
            if "timeline" not in str(self.state.pm_questions).lower():
                if elapsed > 120:  # After 2 minutes, ask about timeline
                    questions.append("What's your timeline for this project?")
            return questions
            
        else:
            # Call the PM Agent via OpenClaw's sessions_spawn
            if not OPENCLAW_AVAILABLE:
                print("Would call real PM agent here, but OpenClaw is not available.")
                return ["Can you provide more specifics on the features discussed?"]
                
            try:
                print("Calling PM Agent via OpenClaw...")
                prompt = f"Analyze this new meeting transcript snippet and generate 1-2 follow up questions to ask the client. If no question is needed, reply with 'None'. Transcript: {transcript}"
                
                response = sessions_spawn(
                    agent="pm",
                    task=prompt
                )
                
                # Check if PM agent actually had a question
                if response and not response.strip().lower().startswith("none"):
                    questions.append(response.strip())
            except Exception as e:
                print(f"Failed to reach PM agent: {e}")
                
            return questions

    def _add_transcript_segment(self, speaker: str, text: str):
        """Add a segment to the transcript."""
        segment = {
            "timestamp": time.time(),
            "speaker": speaker,
            "text": text
        }
        self.state.transcript.append(segment)
        self.state.save(self.state_path)

        # Also append to text file
        with open(self.transcript_path, 'a') as f:
            timestamp = datetime.now().strftime('%H:%M:%S')
            f.write(f"[{timestamp}] {speaker}: {text}\n")

    def _add_pm_question(self, question: str):
        """Add a PM question to the tracking."""
        q = {
            "timestamp": time.time(),
            "question": question,
            "answer": None
        }
        self.state.pm_questions.append(q)
        self.state.save(self.state_path)

    async def end_meeting(self):
        """End the meeting and generate summary."""
        print(f"\n✅ Meeting Ended")
        print(f"Duration: {int(time.time() - self.state.started_at)} seconds")
        print(f"Transcript segments: {len(self.state.transcript)}")
        print(f"PM questions asked: {len(self.state.pm_questions)}")

        self.state.status = "completed"
        self.state.ended_at = time.time()
        self.state.duration_seconds = int(self.state.ended_at - self.state.started_at)
        self.state.save(self.state_path)

        # Generate summary for PM Agent
        summary = self._generate_summary()
        print(f"\n📄 Summary for PM Agent:")
        print(summary)

        # Save summary to file
        summary_path = f"{self.meeting_path}/summary.md"
        with open(summary_path, 'w') as f:
            f.write(summary)
        print(f"\nSummary saved to: {summary_path}")
        
        # Trigger PM Agent to create BRD/SOW/FSD
        if not self.demo and OPENCLAW_AVAILABLE:
            print("\n🚀 Handing off to PM Agent to generate BRD/SOW/FSD...")
            try:
                sessions_spawn(
                    agent="pm",
                    task=f"The meeting is over. Please read the summary and transcript at {self.transcript_path} and generate the BRD, SOW, and FSD. Project name is {self.project_id}."
                )
                print("✅ PM Agent handoff successful!")
            except Exception as e:
                print(f"❌ Failed to handoff to PM Agent: {e}")

    def _generate_summary(self) -> str:
        """Generate a meeting summary for the PM Agent."""
        duration_mins = self.state.duration_seconds // 60
        duration_secs = self.state.duration_seconds % 60

        summary = f"""# Meeting Summary

**Project:** {self.project_id}
**Meeting:** {self.meeting_id}
**Date:** {datetime.fromtimestamp(self.state.started_at).strftime('%Y-%m-%d %H:%M:%S')}
**Duration:** {duration_mins}m {duration_secs}s

## Transcript Summary

Total segments: {len(self.state.transcript)}
Client segments: {sum(1 for s in self.state.transcript if s['speaker'] == 'client')}
Bot segments: {sum(1 for s in self.state.transcript if s['speaker'] == 'meeting_bot')}

## PM Questions Asked

{chr(10).join(f"{i+1}. {q['question']}" for i, q in enumerate(self.state.pm_questions)) if self.state.pm_questions else "No questions asked."}

## Next Steps

Please analyze the full transcript and generate:
1. **BRD** (Business Requirements Document)
2. **SOW** (Statement of Work)
3. **FSD** (Functional Specification Document)

Files to review:
- Full transcript: `{self.transcript_path}`
- Meeting state: `{self.state_path}`
"""
        return summary

# ============== COMMAND LINE INTERFACE ==============

def main():
    import argparse

    parser = argparse.ArgumentParser(description="FORGE Meeting Bot")
    parser.add_argument("--project", required=True, help="Project ID")
    parser.add_argument("--meeting", required=True, help="Meeting ID")
    parser.add_argument("--workspace", default=WORKSPACE, help="Workspace path")
    parser.add_argument("--demo", action="store_true", help="Run in demo mode")
    parser.add_argument("--telegram-token", help="Telegram Bot Token for sending text messages")
    parser.add_argument("--chat-id", help="Telegram Chat ID to post messages to")

    args = parser.parse_args()

    # Check dependencies
    if not WHISPER_AVAILABLE and not args.demo:
        print("ERROR: Whisper not installed.")
        print("Install with: pip install openai-whisper")
        sys.exit(1)

    # Create facilitator
    facilitator = MeetingFacilitator(
        project_id=args.project,
        meeting_id=args.meeting,
        workspace=args.workspace,
        demo=args.demo,
        telegram_token=args.telegram_token,
        chat_id=args.chat_id
    )

    # Start meeting
    try:
        facilitator.start_meeting()
    except KeyboardInterrupt:
        print("\n\n⚠️ Meeting interrupted by user")
        asyncio.run(facilitator.end_meeting())

if __name__ == "__main__":
    main()
