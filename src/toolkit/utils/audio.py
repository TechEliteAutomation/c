# src/toolkit/utils/audio.py

import subprocess
import shlex
import re
import sys
from pathlib import Path
from abc import ABC, abstractmethod

# Import the centralized config helper
from toolkit.utils import config

class TTSEngine(ABC):
    """Abstract base class for a Text-to-Speech engine."""

    def clean_text(self, text: str) -> str:
        """Removes characters that can interfere with TTS command-line execution."""
        # Remove characters that might be misinterpreted by the shell or TTS engine
        cleaned = re.sub(r'[*_`#~"\'!${}()<>|;&]', '', text)
        # Consolidate whitespace to prevent long pauses or odd phrasing
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        return cleaned

    @abstractmethod
    def speak(self, text: str):
        """Synthesizes and speaks the given text."""
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """Checks if the TTS engine and its dependencies are available."""
        pass

class PiperTTS(TTSEngine):
    """TTS implementation using the Piper engine."""
    def __init__(self, executable_path: str, model_path: str):
        self.executable_path = Path(executable_path)
        self.model_path = Path(model_path)
        self._paplay_available: bool | None = None  # Cache the check

    def is_available(self) -> bool:
        if not self.executable_path.is_file():
            print(f"Warning: Piper executable not found at '{self.executable_path}'", file=sys.stderr)
            return False
        if not self.model_path.is_file():
            print(f"Warning: Piper voice model not found at '{self.model_path}'", file=sys.stderr)
            return False
        
        if self._paplay_available is None:
            try:
                # Use 'which' to check for command existence efficiently
                subprocess.run(['which', 'paplay'], capture_output=True, check=True, text=True)
                self._paplay_available = True
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("Warning: `paplay` command not found. Piper TTS cannot play audio.", file=sys.stderr)
                self._paplay_available = False
        
        return self._paplay_available

    def speak(self, text: str):
        if not self.is_available():
            print("Error: Piper TTS is not available or configured correctly.", file=sys.stderr)
            return

        cleaned_text = self.clean_text(text)
        if not cleaned_text:
            return

        # This command uses a shell pipeline. shlex.quote is used to make the text input safe.
        command_str = (
            f"echo {shlex.quote(cleaned_text)} | "
            f"{shlex.quote(str(self.executable_path))} --model {shlex.quote(str(self.model_path))} --output_file - | "
            f"paplay --raw --rate=22050 --format=s16le --channels=1"
        )
        try:
            subprocess.run(command_str, shell=True, check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        except subprocess.CalledProcessError as e:
            print(f"Error during Piper TTS execution: {e}", file=sys.stderr)
            print(f"Piper Stderr: {e.stderr.strip()}", file=sys.stderr)

class ESpeakTTS(TTSEngine):
    """TTS implementation using the eSpeak-NG engine."""
    def __init__(self, voice: str, speed: int, pitch: int):
        self.voice = voice
        self.speed = str(speed)
        self.pitch = str(pitch)
        self._espeak_available: bool | None = None # Cache the check

    def is_available(self) -> bool:
        if self._espeak_available is None:
            try:
                subprocess.run(['which', 'espeak-ng'], capture_output=True, check=True)
                self._espeak_available = True
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("Warning: 'espeak-ng' command not found. eSpeak TTS is unavailable.", file=sys.stderr)
                self._espeak_available = False
        return self._espeak_available

    def speak(self, text: str):
        if not self.is_available():
            print("Error: eSpeak-NG is not available.", file=sys.stderr)
            return

        cleaned_text = self.clean_text(text)
        if not cleaned_text:
            return

        command = ['espeak-ng', '-v', self.voice, '-s', self.speed, '-p', self.pitch, cleaned_text]
        try:
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        except subprocess.CalledProcessError as e:
            print(f"Error during eSpeak-NG execution: {e}", file=sys.stderr)
            print(f"eSpeak-NG Stderr: {e.stderr.strip()}", file=sys.stderr)

def create_tts_engine() -> TTSEngine | None:
    """
    Factory function to create a TTS engine based on the project's config.toml.

    Returns:
        An initialized TTSEngine object (PiperTTS or ESpeakTTS), or None if the
        engine is set to "none" or an error occurs.
    """
    try:
        engine_name = config.get('tts', 'engine').lower()

        if engine_name == "piper":
            executable = config.get('tts', 'piper_executable')
            model = config.get('tts', 'piper_voice_model')
            return PiperTTS(executable_path=executable, model_path=model)
        
        elif engine_name == "espeak":
            voice = config.get('tts', 'espeak_voice')
            speed = config.get('tts', 'espeak_speed', type=int)
            pitch = config.get('tts', 'espeak_pitch', type=int)
            return ESpeakTTS(voice=voice, speed=speed, pitch=pitch)
        
        elif engine_name == "none":
            return None
        
        else:
            print(f"Warning: Unknown TTS engine '{engine_name}' in config.toml. TTS disabled.", file=sys.stderr)
            return None
            
    except Exception as e:
        print(f"Error creating TTS engine from configuration: {e}", file=sys.stderr)
        return None
