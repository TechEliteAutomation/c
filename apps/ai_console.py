#!/usr/bin/env python3
#
# Application Entry Point: AI Console
#
# A command-line interface for conversational AI with optional text-to-speech.
# This application is a thin wrapper around the centralized 'toolkit' library,
# with all configuration managed via the project's 'config.toml' file.
#
import sys
from pathlib import Path

# Add the project's 'src' directory to the Python path to allow 'toolkit' imports.
# This enables running the script directly from the project root.
project_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project_root / 'src'))

try:
    from toolkit.ai import client as ai_client
    from toolkit.utils import audio
except ImportError as e:
    print(f"Error: Failed to import the toolkit library: {e}", file=sys.stderr)
    print("Please ensure you are running this from the project root directory 't'.", file=sys.stderr)
    sys.exit(1)

def main():
    """Main function to run the AI console chat loop."""
    print("--- AI Console Initializing ---")

    try:
        # 1. Initialize the TTS engine from the central configuration.
        # The create_tts_engine factory function handles all config loading and validation.
        print("Initializing TTS engine...")
        tts_engine = audio.create_tts_engine()
        if tts_engine and tts_engine.is_available():
            print("TTS engine is active.")
        else:
            print("TTS is disabled or unavailable.")
            tts_engine = None  # Ensure it's None if not available

        # 2. Initialize the conversational AI session.
        # This also handles its own configuration loading via the toolkit.
        chat_session = ai_client.start_chat_session()
        print("AI chat session is ready.")
        print("-" * 30)
        print("Welcome to the AI Console. Type 'exit' or press Ctrl+C to quit.")
        print("-" * 30)

        # 3. Start the main chat loop
        while True:
            user_input = input("\nYou: ").strip()

            if not user_input:
                continue

            if user_input.lower() == 'exit':
                print("Goodbye!")
                break

            print("AI: Thinking...")
            # Send message to the AI and get the response
            response = chat_session.send_message(user_input)
            ai_response_text = response.text.strip()

            print(f"AI: {ai_response_text}")

            # Speak the response if TTS is active
            if tts_engine:
                tts_engine.speak(ai_response_text)

    except (KeyboardInterrupt, EOFError):
        print("\nExiting console.")
        sys.exit(0)
    except Exception as e:
        print(f"\nCRITICAL ERROR: An unexpected error occurred: {e}", file=sys.stderr)
        print("The application will now exit.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
