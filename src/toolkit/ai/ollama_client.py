# /home/u/c/src/toolkit/ai/ollama_client.py
import requests
import json

class OllamaClient:
    """A client for interacting with a local Ollama server."""
    def __init__(self, host="http://localhost:11434"):
        self.host = host
        print(f"✅ OllamaClient is online, connected to {self.host}")

    def get_response(self, system_prompt: str, chat_history: list, model_name: str):
        """
        Gets a response from a local Ollama model using a more compatible payload format
        that avoids using the 'system' role directly.
        """
        
        # --- THIS IS THE NEW, MORE COMPATIBLE LOGIC ---
        # We will prepend the system prompt to the first user message's content.
        
        # Deep copy the history to avoid modifying the original list
        compatible_history = [msg.copy() for msg in chat_history]

        if compatible_history:
            # Find the first user message to prepend the system prompt to
            first_user_message_index = -1
            for i, msg in enumerate(compatible_history):
                if msg['role'] == 'user':
                    first_user_message_index = i
                    break
            
            if first_user_message_index != -1:
                # Prepend the system prompt to the content of the first user message
                original_content = compatible_history[first_user_message_index]['content']
                compatible_history[first_user_message_index]['content'] = f"{system_prompt}\n\n---\n\nUser: {original_content}"
            else:
                # If no user messages, we can't form a valid chat
                return "Error: No user message found in history to start conversation."
        else:
            return "Error: Chat history is empty."

        try:
            payload = {
                "model": model_name,
                "messages": compatible_history,
                "stream": False
            }

            response = requests.post(
                f"{self.host}/api/chat",
                json=payload,
                timeout=60
            )
            response.raise_for_status()
            
            response_data = response.json()
            return response_data.get("message", {}).get("content", "")

        except requests.exceptions.RequestException as e:
            print(f"🔴 ERROR: Could not connect to Ollama server at {self.host}. Is it running?")
            return f"Error: Could not connect to Ollama. Details: {e}"
