#!/usr/bin/env python3
#
# Application Entry Point: System Analyzer
#
# This script orchestrates the system analysis process:
# 1. Executes the system report generation script.
# 2. Finds the latest generated Markdown and Text reports.
# 3. Reads the content of both reports.
# 4. Sends the content to the Gemini AI for analysis.
# 5. Saves the resulting HTML analysis to the configured reports directory.
#
import sys
from pathlib import Path
from datetime import datetime

# Ensure the 'src' directory is in the Python path to allow toolkit imports
# This makes the app runnable from the project root (e.g., python3 apps/system_analyzer.py)
project_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project_root / 'src'))

from toolkit.utils import config
from toolkit.system import executor
from toolkit.files import operations as file_ops
from toolkit.ai import client as ai_client

def main():
    """Main function to run the system analysis workflow."""
    print("--- Starting System Analyzer Application ---")

    try:
        # 1. Load configuration from the central config.toml file
        print("Loading configuration...")
        report_dir_str = config.get('system_report', 'report_directory')
        report_dir = Path(report_dir_str)
        
        # Define the path to the report generation script relative to the project root
        report_script_path = project_root / 'scripts' / 'system' / 'generate_system_report.sh'
        print(f"Report script located at: {report_script_path}")

        # 2. Execute the shell script to generate system reports
        executor.execute_script(report_script_path)

        # 3. Find the latest generated report files
        print(f"Searching for latest reports in: {report_dir}")
        md_report_path = file_ops.find_latest_file("system_report_*.md", search_path=str(report_dir))
        txt_report_path = file_ops.find_latest_file("system_report_detailed_*.txt", search_path=str(report_dir))

        if not md_report_path or not txt_report_path:
            print("ERROR: Could not find the generated report files. Aborting.")
            sys.exit(1)

        # 4. Read the content of the reports
        md_content = file_ops.read_file(md_report_path)
        txt_content = file_ops.read_file(txt_report_path)

        # 5. Send the report content to the AI for analysis
        # The AI client handles its own configuration (API key, model name)
        html_analysis = ai_client.analyze_system_report(md_content, txt_content)

        if not html_analysis:
            print("ERROR: AI analysis returned no content. Aborting.")
            sys.exit(1)

        # 6. Save the final HTML analysis report
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        output_filename = f"AI_Analysis_Report_{timestamp}.html"
        output_path = report_dir / output_filename
        
        file_ops.save_file(html_analysis, output_path)
        
        print("\n--- System Analysis Complete ---")
        print(f"✅ Success! The final analysis report has been saved to:")
        print(f"   {output_path}")

    except FileNotFoundError as e:
        print(f"\nERROR: A required file or script was not found.")
        print(f"Details: {e}")
        sys.exit(1)
    except (ValueError, RuntimeError, Exception) as e:
        print(f"\nAn unexpected error occurred during the process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
