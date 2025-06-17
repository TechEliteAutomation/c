# apps/system_analyzer.py

from pathlib import Path

# All imports are at the top, and we rely on Poetry's installation
# to make the 'toolkit' package available.
from toolkit.ai import client as ai_client
from toolkit.files import operations as file_ops
from toolkit.system import executor
from toolkit.utils import config


def analyze_system_and_generate_report():
    """
    Analyzes the system, generates a report using an AI model,
    and saves it to a file.
    """
    print("Starting system analysis...")
    try:
        # 1. Load configuration
        cfg = config.load_config()
        ai_cfg = cfg.get("ai", {})
        system_cfg = cfg.get("system_report", {})

        # 2. Generate the system report content
        print("Gathering system information...")
        system_info = executor.get_system_info()

        # 3. Initialize AI client and generate the HTML report
        print("Initializing AI client...")
        ai = ai_client.AIClient(
            provider=ai_cfg.get("provider"), api_key=ai_cfg.get("api_key")
        )

        print("Generating HTML report with AI...")
        html_report = ai.generate_system_report(system_info)

        # 4. Save the report
        output_path_str = system_cfg.get("output_path", "system_report.html")
        output_path = Path(output_path_str)
        print(f"Saving report to {output_path.resolve()}...")
        file_ops.save_text_to_file(html_report, output_path)

        print("\n✅ System analysis report generated successfully!")

    except FileNotFoundError:
        print("\n❌ ERROR: config.toml not found.")
        print("Please ensure a valid config.toml file exists in the project root.")
    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")


if __name__ == "__main__":
    analyze_system_and_generate_report()
