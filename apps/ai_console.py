# apps/ai_console.py

import sys

# We now rely on Poetry to handle the path.
# All imports are clean and at the top.
from toolkit.ai import client as ai_client
from toolkit.utils import audio, config


def main():
    """
    Main function to run the interactive AI console.
    """
    try:
        # Load environment variables for API keys
        config.load_dotenv()
    except Exception as e:
        print(f"Warning: Could not load .env file. {e}")

    try:
        # 1. Initialize the TTS engine
        print("Initializing TTS engine...")
        tts_engine = audio.create_tts_engine()

        # 2. Start the conversational AI session
        chat_session = ai_client.start_chat_session()
        print("\n✅ AI Console is ready. Type 'exit' or 'quit' to end.")
        print("-" * 50)

        # 3. Enter the main interaction loop
        while True:
            user_input = input("You: ")
            if user_input.lower() in ["exit", "quit"]:
                print("Exiting AI Console. Goodbye!")
                break

            response = chat_session.send_message(user_input)
            ai_response_text = response.text

            print(f"\nAI: {ai_response_text}\n")

            # Speak the response if a TTS engine is available
            if tts_engine and tts_engine.is_available():
                tts_engine.speak(ai_response_text)

    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
