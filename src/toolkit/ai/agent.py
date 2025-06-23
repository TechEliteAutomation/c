# /home/u/c/src/toolkit/ai/agent.py

import os
from .client import GeminiClient
from .ollama_client import OllamaClient # Import the new client
from toolkit.system.executor import read_file

class OrchestratorAgent:
    """
    The primary brain of the Axiom system. It now manages multiple AI clients
    and routes requests to the appropriate model.
    """
    def __init__(self, config):
        self.config = config
        self.roles_dir = config.get('roles_dir', 'prompts/roles')
        
        # --- Initialize all available clients ---
        self.clients = {
            "gemini-1.5-pro-latest": GeminiClient(),
            "ollama": OllamaClient() # A generic Ollama client
        }

    def _get_role_prompt(self, role_name: str) -> str:
        """Safely loads a role prompt from the roles directory."""
        prompt_path = os.path.join(self.roles_dir, f"{role_name}.md")
        if not os.path.exists(prompt_path):
            raise FileNotFoundError(f"CRITICAL: Role prompt not found at {prompt_path}")
        return read_file(prompt_path)

    def get_response(self, chat_history: list, persona_name: str, model_key: str):
        """
        Gets a response from the AI, routing to the correct client.
        `model_key` can be 'gemini-1.5-pro-latest' or an ollama model like 'llama3'.
        """
        system_prompt = self._get_role_prompt(persona_name)
        
        if model_key.startswith("gemini"):
            client = self.clients["gemini-1.5-pro-latest"]
            return client.generate_with_tools(system_prompt, chat_history)
        else:
            # Assume it's an Ollama model
            client = self.clients["ollama"]
            # Ollama client handles its own history format
            return client.get_response(system_prompt, chat_history, model_key)
