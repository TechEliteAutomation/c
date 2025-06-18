## **Project: AI Communications Manager - Final Technical Specification**

### **1. Executive Summary**

This document provides the definitive technical specification for the AI Communications Manager, a professional-grade application designed for automated, local-first analysis of a complete communications backlog. The architecture is designed for seamless integration into your existing development framework, leveraging the `src/toolkit` for modular, reusable components and `apps` for the main application logic.

This final version expands the project's scope to include the capture and automated transcription of voice call recordings from both Google Voice and a personal cellular line. By integrating a local speech-to-text engine (`whisper.cpp`), we transform the most labor-intensive manual task (voicemail transcription) into a simple file management operation, creating a highly efficient and unified text and voice data processing pipeline. The system is designed for daily, incremental operation after an initial full-history sync.

### **2. Project Structure Integration**

The following modifications will integrate the application into your framework, establishing a clear separation between code, data, and generated reports.

#### **2.1. New Directories and Files**
_Estimated Time: 5 minutes_

The following commands will scaffold the necessary directory structure.

```bash
# Create directories for data inputs, including a new one for audio
mkdir -p data/comms/google_takeout
mkdir -p data/comms/audio_recordings/processed

# Create directory for generated reports
mkdir -p reports/comms_triage

# Create the new application and toolkit modules
mkdir -p src/toolkit/parsers
touch src/toolkit/parsers/__init__.py
touch src/toolkit/parsers/comms_parser.py
touch apps/comm_triage.py
```

#### **2.2. Gitignore**
_Estimated Time: <1 minute_

Update your root `.gitignore` file to prevent committing sensitive data, generated reports, or local state.

```gitignore
# ~/ai_comms_manager/.gitignore
# Add these lines to your existing file

# --- AI Comms Manager ---
# Ignore all raw and processed data inputs
/data/

# Ignore all generated reports and logs
/reports/

# Ignore application state file
/apps/last_run_timestamps.json
```

### **3. Configuration (`config.toml`)**

_Estimated Time: 5 minutes_

Add the following section to your root `config.toml`. This centralizes all configuration, making the application robust and easy to maintain.

```toml
# ~/ai_comms_manager/config.toml

[comms_triage]
# Ollama Settings
ollama_model = "llama3:8b"
ollama_endpoint = "http://localhost:11434/api/generate"

# Local AI Transcription Settings
whisper_model = "base.en" # (e.g., tiny.en, base.en, small.en)
whisper_cpp_path = "/path/to/your/whisper.cpp" # Absolute path to whisper.cpp directory

# Data and Report Paths
takeout_dir = "data/comms/google_takeout"
sms_xml_file = "data/comms/sms_backup.xml"
audio_dir = "data/comms/audio_recordings"
user_profile_file = "data/comms/user_profile.txt"
reports_dir = "reports/comms_triage"
state_file = "apps/last_run_timestamps.json"
```

### **4. Phase 1: Foundation & Data Extraction**

This phase covers the one-time setup of all tools and data sources.

#### **4.1. Toolchain Setup**
_Estimated Time: 30 - 45 minutes_

1.  **System Packages**: Install `ffmpeg` for audio conversion, which is required by Whisper.
    ```bash
    sudo pacman -Syu ffmpeg
    ```
2.  **Python Dependencies**: Add the required libraries to your project.
    ```bash
    poetry add beautifulsoup4 toml
    ```
3.  **Local Transcription Engine (`whisper.cpp`)**: Clone, compile, and download a model. This provides fast, private, and highly accurate audio transcription.
    ```bash
    git clone https://github.com/ggerganov/whisper.cpp.git /path/to/your/whisper.cpp
    cd /path/to/your/whisper.cpp
    make
    bash ./models/download-ggml-model.sh base.en
    ```
    *Note: Update the `whisper_cpp_path` in `config.toml` to this location.*

#### **4.2. Call Recording & Voice Data Strategy**
_Estimated Time: 15 - 20 minutes for setup_

1.  **Google Voice (Business Line)**: Google Voice provides a reliable, built-in recording feature.
    *   **Setup**: Navigate to the Google Voice settings page. Under `Calls > Incoming call options`, enable `Call options`.
    *   **Workflow**: When you answer a call, press `4` on your keypad to start recording. An audible announcement ("This call is now being recorded") will play. Press `4` again to stop. The resulting `.mp3` file will appear in your email and Google Voice history.
    *   **Daily Task**: Your daily task is to download these `.mp3` files into your `data/comms/audio_recordings/` directory.

2.  **Personal Line (Android)**: Automated call recording on non-rooted, modern Android devices is technically challenging due to OS privacy restrictions.
    *   **Challenge**: Most Play Store apps are unreliable. They may fail to record, capture only your voice via the microphone, or require invasive permissions.
    *   **Recommended Solution (Best Effort)**: Use an application that leverages the Accessibility Service. **Cube ACR** is a well-known option.
    *   **Setup**:
        1.  Install Cube ACR from the Play Store.
        2.  During setup, you must grant it several sensitive permissions, including making it an "enabled app" in the Accessibility menu. This is a **significant privacy and security trade-off** which you must accept to proceed.
        3.  Configure it to automatically record calls and save them to a specific folder on your device's storage.
    *   **Daily Task**: Connect your phone via `adb` or use a sync service to move the new audio recording files from your device to the `data/comms/audio_recordings/` directory.

#### **4.3. Initial Data Export**
_Estimated Time: 1.5 - 4+ hours (dominated by manual data gathering)_

*   **Google Takeout (`takeout_dir`)**: Perform a full export of your Google Voice history. *(15-45 mins)*
*   **SMS Backup (`sms_xml_file`)**: Use "SMS Backup & Restore" to create a single XML backup of your entire SMS history. *(5-10 mins)*
*   **User Profile (`user_profile_file`)**: Generate and save your user profile. *(10-15 mins)*
*   **Historical Voicemails**: For voicemails that exist only as text transcripts (before call recording was set up), they must still be manually transcribed into a temporary file for a one-time import. *(30-120+ mins)*

### **5. Refactored Application Code**

The application is architected for maintainability and clarity, separating concerns into parsers and the main application orchestrator.

#### **5.1. Toolkit: Parsers (`src/toolkit/parsers/comms_parser.py`)**

This module remains focused on parsing structured text formats (XML, HTML).

```python
# ~/ai_comms_manager/src/toolkit/parsers/comms_parser.py
# (Code is unchanged from the previous version, providing parse_sms_xml and parse_google_takeout)
import os
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
import glob
from bs4 import BeautifulSoup
from typing import List, Dict, Any

def parse_sms_xml(xml_file: str, since_timestamp: float = 0.0) -> List[Dict[str, Any]]:
    """Parses an SMS Backup & Restore XML file, returning messages since a timestamp."""
    if not os.path.exists(xml_file): return []
    tree = ET.parse(xml_file)
    messages = []
    for msg in tree.getroot().findall('sms'):
        try:
            ts = int(msg.get('date')) / 1000.0
            if ts <= since_timestamp: continue
            messages.append({
                "source": "personal-sms", "sender": msg.get('address'),
                "timestamp": datetime.fromtimestamp(ts, tz=timezone.utc).isoformat(),
                "content": msg.get('body')
            })
        except (TypeError, ValueError): continue
    return messages

def parse_google_takeout(takeout_dir: str, since_timestamp: float = 0.0) -> List[Dict[str, Any]]:
    """Parses Google Voice HTML files from a Takeout export."""
    if not os.path.isdir(takeout_dir): return []
    messages = []
    for file_path in glob.glob(os.path.join(takeout_dir, "Voice/Calls", "*.html")):
        with open(file_path, 'r', encoding='utf-8') as f: soup = BeautifulSoup(f, 'html.parser')
        for conv in soup.find_all('div', class_='thread'):
            sender = conv.find('a', class_='tel').get('href').replace('tel:', '')
            for msg_div in conv.find_all('div', class_='message'):
                try:
                    dt = datetime.fromisoformat(msg_div.find('abbr', class_='dt').get('title'))
                    if dt.timestamp() <= since_timestamp: continue
                    messages.append({
                        "source": "business-google-voice", "sender": sender,
                        "timestamp": dt.isoformat(),
                        "content": msg_div.find('q').get_text(strip=True)
                    })
                except Exception: continue
    return messages
```

#### **5.2. Main Application (`apps/comm_triage.py`)**

This is the orchestrator. It is significantly updated to include the automated transcription pre-processing step.

```python
# ~/ai_comms_manager/apps/comm_triage.py

import os
import sys
import json
import argparse
import toml
import subprocess
from datetime import datetime
from typing import List, Dict, Any, Optional

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.toolkit.ai.client import ollama_request
from src.toolkit.parsers.comms_parser import parse_sms_xml, parse_google_takeout

# --- Prompt Templates (Truncated) ---
ANONYMIZATION_PROMPT = "..."
TRIAGE_PROMPT = "..."

def load_config() -> Optional[Dict[str, Any]]:
    try:
        config_path = os.path.join(os.path.dirname(sys.path[-1]), 'config.toml')
        return toml.load(config_path).get('comms_triage')
    except Exception as e:
        print(f"❌ Config Error: {e}"); return None

def transcribe_audio_files(cfg: Dict) -> List[Dict[str, Any]]:
    """Transcribes new audio files using whisper.cpp and returns structured data."""
    audio_dir = cfg['audio_dir']
    processed_dir = os.path.join(audio_dir, "processed")
    whisper_path = cfg['whisper_cpp_path']
    model = cfg['whisper_model']
    
    new_communications = []
    audio_files = [f for f in os.listdir(audio_dir) if f.endswith(('.mp3', '.wav', '.m4a'))]
    
    if not audio_files: return []
    print(f"Found {len(audio_files)} new audio file(s) for transcription...")

    for filename in audio_files:
        audio_file_path = os.path.join(audio_dir, filename)
        output_txt_path = os.path.join(audio_dir, filename + ".txt")
        
        cmd = [
            os.path.join(whisper_path, "main"),
            "-m", os.path.join(whisper_path, f"models/ggml-{model}.bin"),
            "-f", audio_file_path, "-otxt", "-nt"
        ]
        
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            with open(output_txt_path, 'r') as f:
                content = f.read().strip()
            
            # Simple parsing from filename (can be improved)
            # Assumes filename format like 'YYYY-MM-DD_HHMM_SENDER.mp3'
            parts = os.path.splitext(filename)[0].split('_')
            timestamp = datetime.strptime(f"{parts[0]} {parts[1]}", "%Y-%m-%d %H%M").astimezone().isoformat()
            sender = parts[2] if len(parts) > 2 else "Unknown Caller"

            new_communications.append({
                "source": "personal-call-recording" if "personal" in sender.lower() else "business-call-recording",
                "sender": sender,
                "timestamp": timestamp,
                "content": content
            })
            
            # Cleanup and archive
            os.remove(output_txt_path)
            os.rename(audio_file_path, os.path.join(processed_dir, filename))
            print(f"✅ Transcribed and processed: {filename}")

        except (subprocess.CalledProcessError, FileNotFoundError, IndexError) as e:
            print(f"❌ Failed to transcribe {filename}: {e}")
            continue
            
    return new_communications

# ... (load_config, read_state, write_state, anonymize_data functions from previous version) ...
# (These functions are unchanged)

def main():
    parser = argparse.ArgumentParser(description="AI Communications Manager")
    # ... (argparse setup unchanged) ...
    args = parser.parse_args()
    cfg = load_config();
    if not cfg: sys.exit(1)

    # --- 0. Transcription Pre-processing ---
    print("\n[Phase 0/4] Checking for new audio recordings...")
    transcribed_data = transcribe_audio_files(cfg)

    # --- 1. Data Extraction ---
    print("\n[Phase 1/4] Extracting text-based data...")
    # ... (unchanged logic for parsing SMS, Google Voice, and getting manual data) ...
    # ... (manual data entry is now for one-off historical items, not daily voicemails) ...
    
    all_data = transcribed_data + sms_data + gvoice_data + manual_data
    if not all_data:
        print("\n✅ No new communications to process.")
        return

    # --- 2. Anonymization ---
    print(f"\n[Phase 2/4] Anonymizing {len(all_data)} total items...")
    # ... (anonymization logic unchanged) ...

    # --- 3. Triage and Reporting ---
    print("\n[Phase 3/4] Generating Triage Report...")
    # ... (report generation logic unchanged) ...

if __name__ == "__main__":
    main()
```

### **6. Usage and Workflow**

#### **6.1. Initial Setup & Backlog Clearance**
_Estimated Time: 2 - 6 hours (dominated by one-time data tasks)_

1.  **Complete Setup**: Follow all steps in Phase 1.
2.  **Execute Full Sync**: Run the main application with the `--full-sync` flag. This will process all historical data, run the lengthy anonymization process, and generate your `MASTER_TRIAGE_REPORT.md`.
    ```bash
    python apps/comm_triage.py --full-sync
    ```

#### **6.2. Daily Operational Workflow**
_Estimated Time: 5 - 10 minutes_

Your daily routine is now streamlined to simple file management followed by a single command.

1.  **Gather Audio**: Move any new call recordings from your phone(s) into the `data/comms/audio_recordings/` directory.
2.  **Update SMS Backup**: Ensure "SMS Backup & Restore" has run its daily schedule, updating the `sms_backup.xml` file.
3.  **Run Daily Triage**: Execute the script with the `--daily` flag.
    ```bash
    python apps/comm_triage.py --daily
    ```
    The script will first transcribe new audio, then process new text messages, and finally generate your date-stamped daily report in `reports/comms_triage/`.
