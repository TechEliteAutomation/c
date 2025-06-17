# src/toolkit/ai/client.py

import os
import google.generativeai as genai
from google.generativeai.types import GenerationConfig
from google.generativeai.generative_models import ChatSession
from toolkit.utils import config

# A flag to ensure this setup runs only once per session for efficiency.
_is_configured = False

def configure_gemini():
    """
    Configures the Google Generative AI client using the GEMINI_API_KEY
    environment variable. Designed to be called once per session.
    """
    global _is_configured
    if _is_configured:
        return

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError(
            "CRITICAL: GEMINI_API_KEY environment variable not found. "
            "Please export it in your shell configuration."
        )

    try:
        genai.configure(api_key=api_key)
        _is_configured = True
    except Exception as e:
        print(f"Failed to configure Gemini client. Error: {e}")
        raise

def start_chat_session() -> ChatSession:
    """
    Initializes and returns a new conversational chat session with the Gemini model.

    The session is configured using parameters from the central config.toml file.
    The returned ChatSession object maintains its own history.

    Returns:
        A configured ChatSession object from the google-generativeai library.
    """
    configure_gemini()

    try:
        model_name = config.get('ai', 'model_name')
        temperature = config.get('ai', 'temperature', type=float)
        max_tokens = config.get('ai', 'max_output_tokens', type=int)
    except Exception as e:
        raise RuntimeError(
            f"Failed to load AI chat configuration from config.toml: {e}"
        ) from e

    print(f"Initializing conversational AI model: {model_name}")
    model = genai.GenerativeModel(model_name)

    chat_session = model.start_chat(
        history=[],
        generation_config=GenerationConfig(
            temperature=temperature,
            max_output_tokens=max_tokens
        )
    )
    return chat_session

def analyze_system_report(md_report_content: str, txt_report_content: str) -> str:
    """
    Analyzes system report data using the configured Gemini model. This is a
    single-turn function, distinct from the conversational chat session.

    Args:
        md_report_content: The content of the markdown system report.
        txt_report_content: The content of the detailed text system report.

    Returns:
        A string containing the generated HTML analysis.
    """
    configure_gemini()

    try:
        model_name = config.get('ai', 'model_name')
    except Exception as e:
        raise RuntimeError(
            f"Failed to load AI analysis configuration from config.toml: {e}"
        ) from e

    print(f"Initializing analysis AI model: {model_name}...")
    model = genai.GenerativeModel(model_name)

    prompt = _build_analysis_prompt(md_report_content, txt_report_content)
    print("Sending prompt to Gemini for analysis...")

    try:
        response = model.generate_content(prompt)
        html_content = response.text.strip() if response.text else ""
        print("Successfully received HTML analysis from Gemini.")
        return html_content
    except Exception as e:
        print(f"An error occurred during the Gemini API call: {e}")
        raise

def _build_analysis_prompt(md_content: str, txt_content: str) -> str:
    """Builds the detailed prompt for the system analysis task."""
    # This is a long, static prompt. Its content remains unchanged.
    return f"""
You are an expert system analyst. Analyze the following Arch Linux system information.
Provide a comprehensive analysis as a single, well-formed HTML document.

The HTML analysis should:
1.  Overview: OS (Arch Linux), Kernel, Hostname, Uptime.
2.  CPU: Model, cores, speed, virtualization.
3.  Memory: Total, used, free, swap.
4.  Disk: Partitions, usage, types.
5.  GPU: If present.
6.  Network: Interface names/states, default route. Note privacy omissions.
7.  Packages/Services: Notable Arch Linux packages (pacman) or systemd services.
8.  Issues: Identify potential problems, bottlenecks, optimizations, security considerations.
9.  Recommendations: Clear next steps for maintenance/improvement for an Arch Linux system.
10. HTML Structure: Use <h1>, <h2>, <p>, <ul>/<ol>, <table>, <code>, <pre>.
11. Output: ONLY the HTML document (<!DOCTYPE html> to </html>).
12. Styling (Solarized Dark Theme - embed CSS in <style> in <head>):
    body {{ background-color: #002b36; color: #839496; font-family: sans-serif; margin: 20px; line-height: 1.6; }}
    h1, h2, h3 {{ color: #268bd2; border-bottom: 1px solid #586e75; padding-bottom: 0.3em; margin-top: 1.5em; }}
    h1 {{ font-size: 2em; }} h2 {{ font-size: 1.5em; }}
    table {{ border-collapse: collapse; width: 95%; margin: 1em auto; box-shadow: 0 2px 3px rgba(0,0,0,0.1); }}
    th, td {{ border: 1px solid #586e75; padding: 10px 12px; text-align: left; }}
    th {{ background-color: #073642; color: #93a1a1; font-weight: bold; }}
    tr:nth-child(even) {{ background-color: #073642; }}
    pre, code {{ background-color: #073642; color: #b58900; padding: 0.2em 0.4em; border-radius: 4px; font-family: 'Courier New', Courier, monospace; }}
    pre {{ padding: 1em; overflow-x: auto; display: block; white-space: pre-wrap; word-wrap: break-word; border: 1px solid #586e75; }}
    p code {{ display: inline; padding: 0.1em 0.3em; }}
    ul, ol {{ margin-left: 25px; padding-left: 0; }} li {{ margin-bottom: 0.5em; }}
    a {{ color: #b58900; text-decoration: none; }} a:hover {{ color: #cb4b16; text-decoration: underline; }}
    .overview-box {{ background-color: #073642; border: 1px solid #586e75; padding: 15px; margin-bottom: 20px; border-radius: 5px; }}
    .recommendations {{ border-left: 3px solid #859900; padding-left: 15px; background-color: #073642; }}
    .issues {{ border-left: 3px solid #dc322f; padding-left: 15px; background-color: #073642; }}

System Information:
---
Markdown Report:
---
{md_content or "Markdown report not available."}
---
Detailed Text Report:
---
{txt_content or "Detailed text report not available."}
---

Generate the HTML analysis now.
"""
