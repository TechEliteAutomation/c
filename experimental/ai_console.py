# ai_console.py

import os
import json
from toolkit.ai.agent import OrchestratorAgent
from toolkit.utils.config import get_axiom_config
from toolkit.system.executor import read_file, create_file

class AxiomConsole:
    """
    An interactive, stateful console for interacting with the Axiom agentic framework.
    """
    def __init__(self):
        print("Initializing Axiom Console...")
        self.config = get_axiom_config()
        self.orchestrator = OrchestratorAgent(self.config)
        self.session_artifacts = {} # In-memory state for this session
        print("✅ Console ready. Type '/help' for a list of commands.")

    def print_help(self):
        """Prints the list of available commands."""
        print("\n--- Axiom Console Commands ---")
        print("/help              - Show this help message.")
        print("/new_prompt <idea> - Generate a new prompt from an idea.")
        print("/new_plan <goal>   - Generate an implementation plan from a goal.")
        print("/execute <path>    - (Simulated) Execute a plan from a file.")
        print("/list              - List all files created in this session.")
        print("/read <filename>   - Read a file created in this session.")
        print("/quit              - Exit the console.")
        print("------------------------------\n")

    def add_artifact(self, filename):
        """Adds a newly created file to the session state."""
        # Use a simple name for user interaction, but store the full path
        simple_name = os.path.basename(filename)
        self.session_artifacts[simple_name] = filename
        print(f"-> Artifact '{simple_name}' is now tracked in this session.")

    def handle_command(self, user_input):
        """Parses and handles commands that start with '/'."""
        parts = user_input.split(" ", 1)
        command = parts[0]
        args = parts[1] if len(parts) > 1 else ""

        if command == "/help":
            self.print_help()
        
        elif command == "/new_prompt":
            if not args:
                print("🔴 Usage: /new_prompt <your prompt idea>")
                return
            output_file = f"workspace/prompt_{len(self.session_artifacts)}.md"
            self.orchestrator.generate_prompt_from_idea(args, output_file)
            self.add_artifact(output_file)

        elif command == "/new_plan":
            if not args:
                print("🔴 Usage: /new_plan <your project goal>")
                return
            output_file = f"workspace/plan_{len(self.session_artifacts)}.md"
            self.orchestrator.generate_plan_from_goal(args, output_file)
            self.add_artifact(output_file)

        elif command == "/execute":
            if not args:
                print("🔴 Usage: /execute <path_to_plan_file>")
                return
            self.orchestrator.execute_plan_from_file(args)

        elif command == "/list":
            if not self.session_artifacts:
                print("No artifacts created in this session yet.")
                return
            print("Session Artifacts:")
            for name in self.session_artifacts.keys():
                print(f"  - {name}")

        elif command == "/read":
            if not args:
                print("🔴 Usage: /read <filename>")
                return
            
            filepath = self.session_artifacts.get(args)
            if not filepath:
                print(f"🔴 Error: Artifact '{args}' not found in this session.")
                return
            
            print(f"\n--- Content of {args} ---\n")
            content = read_file(filepath)
            print(content)
            print("\n--- End of Content ---\n")

        elif command == "/quit":
            return False # Signal to exit the loop
            
        else:
            print(f"🔴 Unknown command: '{command}'. Type '/help' for options.")
        
        return True # Signal to continue the loop

    def start(self):
        """Starts the main Read-Eval-Print Loop (REPL)."""
        running = True
        while running:
            try:
                user_input = input("axiom> ")
                if not user_input:
                    continue
                
                if user_input.startswith('/'):
                    running = self.handle_command(user_input)
                else:
                    # For now, general chat is not implemented.
                    # This is where you could add a direct conversation with a core agent.
                    print("Conversation mode not yet implemented. Please use a command. Type '/help' for options.")

            except (KeyboardInterrupt, EOFError):
                running = False
        
        print("\nExiting Axiom Console. Goodbye.")


if __name__ == "__main__":
    console = AxiomConsole()
    console.start()
