# /home/u/c/src/toolkit/ai/client.py

import os
import google.generativeai as genai
from google.generativeai.types import GenerationConfig, Tool, FunctionDeclaration, HarmCategory, HarmBlockThreshold

class GeminiClient:
    """
    A standardized client for interacting with the Gemini API,
    now with native support for Tool Calling.
    """
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("CRITICAL: GEMINI_API_KEY environment variable not found.")
        
        genai.configure(api_key=api_key)

        # --- Define the tools the model can use ---
        self.tools = [
            FunctionDeclaration(
                name="create_file",
                description="Creates a new file with specified content.",
                parameters={
                    "type": "object",
                    "properties": {
                        "path": {"type": "string", "description": "The relative path for the new file."},
                        "content": {"type": "string", "description": "The content to write into the file."}
                    },
                    "required": ["path", "content"]
                },
            ),
            FunctionDeclaration(
                name="read_file",
                description="Reads the content of a file.",
                parameters={
                    "type": "object",
                    "properties": {
                        "path": {"type": "string", "description": "The relative path of the file to read."}
                    },
                    "required": ["path"]
                },
            ),
        ]

        self.model = genai.GenerativeModel(
            model_name='gemini-1.5-pro-latest',
            tools=self.tools
        )
        print("✅ GeminiClient with Native Tools is online.")

    def generate_with_tools(self, system_prompt: str, chat_history: list):
        """
        Generates a response using the full chat history and available tools.
        Returns the entire response object.
        """
        # Convert our simple history to the format Gemini requires
        gemini_history = []
        for msg in chat_history:
            role = 'user' if msg['role'] == 'user' else 'model'
            gemini_history.append({'role': role, 'parts': [{'text': msg['content']}]})

        # The last message is the current user prompt
        latest_prompt = gemini_history.pop()['parts']

        chat = self.model.start_chat(history=gemini_history)
        
        return chat.send_message(latest_prompt)
