# /home/u/c/axiom_tui.py

import os
from textual.app import App, ComposeResult
from textual.containers import Container, VerticalScroll
from textual.widgets import Header, Footer, Static, Log, Input, DirectoryTree, Markdown
from textual.binding import Binding

from toolkit.ai.agent import OrchestratorAgent
from toolkit.utils.config import get_axiom_config

class AxiomTUI(App):
    """An interactive Text-based User Interface for the Axiom Framework."""

    TITLE = "Axiom TUI v0.2.1"
    SUB_TITLE = "The Interactive Agentic Development Environment"

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("ctrl+s", "toggle_sidebar", "Toggle Sidebar"),
        Binding("ctrl+l", "clear_log", "Clear Log"),
    ]

    def __init__(self):
        super().__init__()
        self.config = get_axiom_config()
        self.orchestrator = OrchestratorAgent(self.config)
        self.workspace_path = self.config.get('workspace_dir', 'workspace')
        self.chat_history = [] # Stateful chat history for the session
        if not os.path.exists(self.workspace_path):
            os.makedirs(self.workspace_path)

    def compose(self) -> ComposeResult:
        """Create child widgets for the app."""
        yield Header()
        with Container(id="main-container"):
            yield DirectoryTree(self.workspace_path, id="sidebar")
            with VerticalScroll(id="viewer-container"):
                yield Markdown("### Select a file to view...", id="viewer")
        yield Log(id="console-log", auto_scroll=True, classes="hidden") # Start hidden
        yield Input(placeholder="/help for commands | Type to chat...")
        yield Footer()

    def on_mount(self) -> None:
        """Called when the app is first mounted."""
        self.query_one(Input).focus()
        self.log_message("Axiom TUI Initialized. Welcome.")

    def on_directory_tree_file_selected(self, event: DirectoryTree.FileSelected) -> None:
        """Called when the user clicks a file in the DirectoryTree."""
        viewer = self.query_one("#viewer", Markdown)
        try:
            with open(event.path, "r") as file:
                viewer.update(file.read())
        except Exception as e:
            viewer.update(f"## Error reading file\n\n```\n{e}\n```")

    def _get_workspace_context(self) -> dict:
        """
        Walks the workspace directory and builds a dictionary of all files
        to provide as context to the conversational agent.
        """
        file_context = {}
        for root, _, files in os.walk(self.workspace_path):
            for name in files:
                full_path = os.path.join(root, name)
                # Use a simplified name for the key, relative to the workspace
                simple_name = os.path.relpath(full_path, self.workspace_path)
                file_context[simple_name] = full_path
        return file_context

    async def on_input_submitted(self, event: Input.Submitted) -> None:
        """Called when the user hits enter in the Input widget."""
        user_input = event.value
        self.log_message(f"axiom> {user_input}")
        self.query_one(Input).value = ""

        if user_input.startswith('/'):
            await self.handle_command(user_input)
        else:
            # Enter conversation mode
            self.chat_history.append({"role": "user", "content": user_input})
            
            # --- THIS IS THE CORRECTED LINE ---
            file_context = self._get_workspace_context()
            
            response = self.orchestrator.have_conversation(self.chat_history, user_input, file_context)
            
            self.log_message(f"> {response}")
            self.chat_history.append({"role": "model", "content": response})

    def log_message(self, message: str):
        """Helper to write to the log."""
        log = self.query_one(Log)
        if log.has_class("hidden"):
            log.remove_class("hidden")
        log.write_line(message)

    async def handle_command(self, user_input: str):
        """Handles application-specific commands."""
        parts = user_input.split(" ", 1)
        command = parts
        args = parts if len(parts) > 1 else ""

        if command == "/help":
            self.log_message("Commands: /new_plan <goal>, /new_prompt <idea>, /clear, /quit")
        
        elif command == "/new_prompt":
            if not args: return self.log_message("🔴 Usage: /new_prompt <idea>")
            output_file = os.path.join(self.workspace_path, f"prompt_{len(os.listdir(self.workspace_path))}.md")
            self.orchestrator.generate_prompt_from_idea(args, output_file)
            self.query_one(DirectoryTree).reload()

        elif command == "/new_plan":
            if not args: return self.log_message("🔴 Usage: /new_plan <goal>")
            output_file = os.path.join(self.workspace_path, f"plan_{len(os.listdir(self.workspace_path))}.md")
            self.orchestrator.generate_plan_from_goal(args, output_file)
            self.query_one(DirectoryTree).reload()
            
        elif command == "/clear":
            self.query_one(Log).clear()
            self.chat_history.clear()
            self.log_message("Console and chat history cleared.")

        else:
            self.log_message(f"🔴 Unknown command: '{command}'")

    def action_toggle_sidebar(self) -> None:
        """Called when the user presses Ctrl+S."""
        sidebar = self.query_one("#sidebar")
        sidebar.toggle_class("hidden")
        
    def action_clear_log(self) -> None:
        """Called when the user presses Ctrl+L."""
        self.query_one(Log).clear()
        self.chat_history.clear()
        self.log_message("Console and chat history cleared.")

if __name__ == "__main__":
    app = AxiomTUI()
    app.run()
