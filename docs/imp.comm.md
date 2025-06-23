## **Project: AI Communications Manager - Final Technical Specification (v2)**

### **1. Executive Summary**

This document provides the definitive technical specification for the AI Communications Manager, a professional-grade application designed for automated, local-first analysis of a complete communications backlog. The architecture is designed for seamless integration into your existing development framework, leveraging the `src/toolkit` for modular, reusable components and `apps` for the main application logic.

This final version expands the project's scope to include two critical data sources: the capture and automated transcription of voice call recordings, and the direct, automated ingestion of emails from a specified sender (`softrol`) via the Gmail API. By integrating a local speech-to-text engine (`whisper.cpp`) and a secure API client, we transform labor-intensive manual data gathering into a fully automated, unified text, voice, and email processing pipeline. The system is designed for daily, incremental operation after an initial full-history sync.

### **2. Project Structure Integration**

The following modifications will integrate the application into your framework, establishing a clear separation between code, data, and generated reports.

#### **2.1. New Directories and Files**
_Estimated Time: 5 minutes_

The following commands will scaffold the necessary directory structure.

```bash
# Create directories for data inputs, including audio and API credentials
mkdir -p data/comms/google_takeout
mkdir -p data/comms/audio_recordings/processed
mkdir -p data/comms/api_credentials

# Create directory for generated reports
mkdir -p reports/comms_triage

# Create the new application and toolkit modules
mkdir -p src/toolkit/parsers
touch src/toolkit/parsers/__init__.py
touch src/toolkit/parsers/comms_parser.py
touch src/toolkit/parsers/email_parser.py # New module for Gmail
touch apps/comm_triage.py
```

#### **2.2. Gitignore**
_Estimated Time: <1 minute_

Update your root `.gitignore` file to prevent committing sensitive data.

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

# Ignore sensitive API tokens
/data/comms/api_credentials/token.json
```

### **3. Configuration (`config.toml`)**

_Estimated Time: 5 minutes_

Add the following section to your root `config.toml`.

```toml
# ~/ai_comms_manager/config.toml

[comms_triage]
# Ollama Settings
ollama_model = "llama3:8b"
ollama_endpoint = "http://localhost:11434/api/generate"

# Local AI Transcription Settings
whisper_model = "base.en"
whisper_cpp_path = "/path/to/your/whisper.cpp"

# Gmail API Settings
gmail_credentials_path = "data/comms/api_credentials/credentials.json"
gmail_token_path = "data/comms/api_credentials/token.json"
gmail_query = "from:softrol" # Standard Gmail search query

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
_Estimated Time: 45 - 60 minutes_

1.  **System Packages**: Install `ffmpeg` for audio conversion.
    ```bash
    sudo pacman -Syu ffmpeg
    ```
2.  **Python Dependencies**: Add the required libraries to your project.
    ```bash
    poetry add beautifulsoup4 toml google-api-python-client google-auth-httplib2 google-auth-oauthlib
    ```
3.  **Local Transcription Engine (`whisper.cpp`)**: Clone, compile, and download a model.
    ```bash
    git clone https://github.com/ggerganov/whisper.cpp.git /path/to/your/whisper.cpp
    cd /path/to/your/whisper.cpp
    make
    bash ./models/download-ggml-model.sh base.en
    ```
    *Note: Update the `whisper_cpp_path` in `config.toml` to this location.*

#### **4.2. Gmail API Setup (One-Time)**
_Estimated Time: 15 - 20 minutes_

This procedure authorizes the application to read your email securely.

1.  **Enable API**: Go to the [Google Cloud Console](https://console.cloud.google.com/). Create a new project, search for "Gmail API", and enable it.
2.  **Create Credentials**:
    *   Navigate to "APIs & Services" > "Credentials".
    *   Click "Create Credentials" > "OAuth client ID".
    *   If prompted, configure the "OAuth consent screen". Select "External" and provide a name for the app (e.g., "Local Comms Manager").
    *   For "Application type", select **"Desktop app"**.
3.  **Download Credentials**: After creation, click the "Download JSON" icon next to the new client ID. Save this file as `credentials.json` inside your `data/comms/api_credentials/` directory.
4.  **Authorize Application**: The first time `email_parser.py` runs, it will open a browser window asking you to log in and grant permission. Upon success, it will automatically create a `token.json` file (specified by `gmail_token_path` in your config). This file will be used for all future, non-interactive runs.

#### **4.3. Call Recording & Voice Data Strategy**
*(This section is unchanged)*

#### **4.4. Initial Data Export**
*(This section is simplified as Gmail is now automated)*
_Estimated Time: 1.5 - 4+ hours (dominated by manual data gathering)_

*   **Google Takeout (`takeout_dir`)**: Perform a full export of your Google Voice history. *(15-45 mins)*
*   **SMS Backup (`sms_xml_file`)**: Use "SMS Backup & Restore" to create a single XML backup. *(5-10 mins)*
*   **User Profile (`user_profile_file`)**: Generate and save your user profile. *(10-15 mins)*
*   **Historical Voicemails**: Manually transcribe any legacy voicemails for one-time import. *(30-120+ mins)*

### **5. Refactored Application Code**

#### **5.1. Toolkit: Comms Parser (`src/toolkit/parsers/comms_parser.py`)**
*(This module is unchanged)*

#### **5.2. New Toolkit: Email Parser (`src/toolkit/parsers/email_parser.py`)**
This new module handles all interaction with the Gmail API.

```python
# ~/ai_comms_manager/src/toolkit/parsers/email_parser.py
import os
import base64
from datetime import datetime, timezone
from typing import List, Dict, Any

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]

def _get_gmail_service(creds_path: str, token_path: str):
    creds = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(token_path, 'w') as token:
            token.write(creds.to_json())
    return build('gmail', 'v1', credentials=creds)

def parse_gmail(creds_path: str, token_path: str, query: str, since_timestamp: float = 0.0) -> List[Dict[str, Any]]:
    """Parses Gmail messages matching a query since a given timestamp."""
    if since_timestamp > 0:
        since_date = datetime.fromtimestamp(since_timestamp).strftime('%Y/%m/%d')
        query += f" after:{since_date}"

    try:
        service = _get_gmail_service(creds_path, token_path)
        results = service.users().messages().list(userId='me', q=query).execute()
        messages_info = results.get('messages', [])
        
        communications = []
        if not messages_info:
            return communications

        for msg_info in messages_info:
            msg = service.users().messages().get(userId='me', id=msg_info['id'], format='full').execute()
            
            ts = int(msg['internalDate']) / 1000.0
            if ts <= since_timestamp: continue

            headers = {h['name']: h['value'] for h in msg['payload']['headers']}
            sender = headers.get('From', 'Unknown Sender')
            
            content = ""
            if 'parts' in msg['payload']:
                for part in msg['payload']['parts']:
                    if part['mimeType'] == 'text/plain':
                        content = base64.urlsafe_b64decode(part['body']['data']).decode('utf-8')
                        break
            else: # Not a multipart message
                if 'data' in msg['payload']['body']:
                    content = base64.urlsafe_b64decode(msg['payload']['body']['data']).decode('utf-8')

            communications.append({
                "source": "gmail-softrol",
                "sender": sender,
                "timestamp": datetime.fromtimestamp(ts, tz=timezone.utc).isoformat(),
                "content": f"Subject: {headers.get('Subject', 'N/A')}\n\n{content.strip()}"
            })
        return communications
    except (HttpError, FileNotFoundError) as e:
        print(f"❌ Gmail API Error: {e}. Ensure 'credentials.json' is correct and you have authorized the app.")
        return []

```

#### **5.3. Main Application (`apps/comm_triage.py`)**
The orchestrator is updated to call the new email parser.

```python
# ~/ai_comms_manager/apps/comm_triage.py
# ... (imports and prompt templates are mostly unchanged) ...
import os
import sys
import json
import argparse
import toml
import subprocess
from datetime import datetime
from typing import List, Dict, Any, Optional

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.toolkit.ai.client import ollama_request
from src.toolkit.parsers.comms_parser import parse_sms_xml, parse_google_takeout
from src.toolkit.parsers.email_parser import parse_gmail # Import the new parser

# ... (ANONYMIZATION_PROMPT, TRIAGE_PROMPT, load_config, transcribe_audio_files, etc. are unchanged) ...

def main():
    parser = argparse.ArgumentParser(description="AI Communications Manager")
    # ... (argparse setup unchanged) ...
    args = parser.parse_args()
    cfg = load_config()
    if not cfg: sys.exit(1)

    state = read_state(cfg['state_file'])
    since_ts = 0.0 if args.full_sync else state.get('last_run_utc', 0.0)

    # --- 0. Transcription Pre-processing ---
    print("\n[Phase 0/5] Checking for new audio recordings...")
    transcribed_data = transcribe_audio_files(cfg)

    # --- 1. Data Extraction ---
    print("\n[Phase 1/5] Extracting text-based data...")
    sms_data = parse_sms_xml(cfg['sms_xml_file'], since_ts)
    gvoice_data = parse_google_takeout(cfg['takeout_dir'], since_ts)
    
    # --- 2. Email Ingestion ---
    print("\n[Phase 2/5] Fetching new emails from Gmail...")
    email_data = parse_gmail(
        cfg['gmail_credentials_path'],
        cfg['gmail_token_path'],
        cfg['gmail_query'],
        since_ts
    )
    
    manual_data = get_manual_entry() if args.manual else []
    
    all_data = transcribed_data + sms_data + gvoice_data + email_data + manual_data
    if not all_data:
        print("\n✅ No new communications to process.")
        return

    # --- 3. Anonymization ---
    print(f"\n[Phase 3/5] Anonymizing {len(all_data)} total items...")
    # ... (anonymization logic unchanged) ...

    # --- 4. Triage and Reporting ---
    print("\n[Phase 4/5] Generating Triage Report...")
    # ... (report generation logic unchanged) ...

    # --- 5. State Update ---
    print("\n[Phase 5/5] Finalizing run...")
    # ... (state update logic unchanged) ...

if __name__ == "__main__":
    main()
```

### **6. Usage and Workflow**

#### **6.1. Initial Setup & Backlog Clearance**
_Estimated Time: 2.5 - 6.5 hours_

1.  **Complete Setup**: Follow all steps in Phase 1, including the Gmail API setup.
2.  **Authorize & Execute Full Sync**: Run the main application with the `--full-sync` flag. The first run will trigger the one-time browser authentication for Gmail.
    ```bash
    python apps/comm_triage.py --full-sync
    ```

#### **6.2. Daily Operational Workflow**
_Estimated Time: 5 - 10 minutes_

Your daily routine is now streamlined to simple file management followed by a single command. The Gmail portion is fully automated.

1.  **Gather Audio**: Move any new call recordings into `data/comms/audio_recordings/`.
2.  **Update SMS Backup**: Ensure "SMS Backup & Restore" has run its daily schedule.
3.  **Run Daily Triage**: Execute the script. It will automatically and incrementally fetch new emails, audio, and texts.
    ```bash
    python apps/comm_triage.py --daily
    ```
