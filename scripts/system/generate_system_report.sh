#!/bin/bash
#
# Generates comprehensive system reports in both Markdown and plain text formats.
# Refactored to integrate with the project's central config.toml.
#

# --- Script Setup ---
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- Configuration Loading ---
load_config() {
    local key="$1"
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    # Go up two levels from scripts/system/ to the project root
    local ROOT_DIR
    ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
    local CONFIG_FILE="$ROOT_DIR/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE" >&2
        exit 1
    fi

    # Use awk for robust parsing: find [system_report] section, then find the key.
    local value
    value=$(awk -F'=' '/^\[system_report\]/{in_section=1} /^\[/{if(!/^\[system_report\]/) in_section=0} in_section && /^\s*'"$key"'\s*=/{gsub(/[ \t"]/, "", $2); print $2; exit}' "$CONFIG_FILE")

    if [ -z "$value" ]; then
        echo "Error: Key '$key' not found under [system_report] section in $CONFIG_FILE" >&2
        exit 1
    fi

    # Manually expand the tilde (~) to the user's home directory.
    value="${value/\~/$HOME}"
    echo "$value"
}

# --- Script Configuration ---
REPORT_DIR=$(load_config "report_directory")
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
MD_OUTPUT_FILE="$REPORT_DIR/system_report_${TIMESTAMP}.md"
TXT_OUTPUT_FILE="$REPORT_DIR/system_report_detailed_${TIMESTAMP}.txt"
SEPARATOR="========================================"

# --- Helper Functions ---
add_header() {
    local file="$1"
    local title="$2"
    local level="${3:-##}"
    if [[ "$file" == *".md"* ]]; then
        echo -e "\n${level} ${title}\n" >> "$file"
    else
        echo -e "\n${SEPARATOR}\n${title}\n${SEPARATOR}\n" >> "$file"
    fi
}

run_and_append() {
    local file="$1"
    local cmd_to_run_str="$2"
    bash -o pipefail -c "$cmd_to_run_str" >> "$file"
}

# --- Main Execution ---
echo "Starting system report generation..."
echo "Report directory: $REPORT_DIR"

# Ensure the report directory exists
mkdir -p "$REPORT_DIR"

# --- Initial File Creation ---
HOSTNAME_INFO=$(hostname)
OS_INFO="Arch Linux"
if [ -f /etc/os-release ]; then . /etc/os-release; OS_INFO="${PRETTY_NAME:-$OS_INFO}"; fi
KERNEL_INFO=$(uname -r)
ARCH_INFO=$(uname -m)
UPTIME_INFO=$(uptime -p)

echo "# System Information Report (Arch Linux)\n\nGenerated on: $(date '+%Y-%m-%d %H:%M:%S %Z')\n" > "$MD_OUTPUT_FILE"
echo -e "${SEPARATOR}\nSYSTEM INFORMATION REPORT (Arch Linux)\n${SEPARATOR}\nGenerated on: $(date '+%Y-%m-%d %H:%M:%S %Z')\n" > "$TXT_OUTPUT_FILE"

# --- System Overview ---
add_header "$MD_OUTPUT_FILE" "System Overview"
cat << EOF >> "$MD_OUTPUT_FILE"
- **Hostname:** ${HOSTNAME_INFO}
- **Operating System:** ${OS_INFO}
- **Kernel:** ${KERNEL_INFO}
- **Architecture:** ${ARCH_INFO}
- **Uptime:** ${UPTIME_INFO}
EOF
add_header "$TXT_OUTPUT_FILE" "SYSTEM OVERVIEW"
cat << EOF >> "$TXT_OUTPUT_FILE"
Hostname:         ${HOSTNAME_INFO}
Operating System: ${OS_INFO}
Kernel:           ${KERNEL_INFO}
Architecture:     ${ARCH_INFO}
Uptime:           ${UPTIME_INFO}
EOF

# --- Hardware Details ---
add_header "$MD_OUTPUT_FILE" "CPU Information"; run_and_append "$MD_OUTPUT_FILE" "lscpu | grep -E 'Model name|Architecture|CPU\(s\):|Core\(s\) per socket|Thread\(s\) per core|CPU MHz|Virtualization:' | sed 's/^/- **/' | sed 's/:/:**/'"
add_header "$TXT_OUTPUT_FILE" "CPU INFORMATION"; run_and_append "$TXT_OUTPUT_FILE" "lscpu"

add_header "$MD_OUTPUT_FILE" "Memory Information"; echo '```' >> "$MD_OUTPUT_FILE"; run_and_append "$MD_OUTPUT_FILE" "free -h"; echo '```' >> "$MD_OUTPUT_FILE"
add_header "$TXT_OUTPUT_FILE" "MEMORY INFORMATION"; run_and_append "$TXT_OUTPUT_FILE" "free -h"; echo "" >> "$TXT_OUTPUT_FILE"; run_and_append "$TXT_OUTPUT_FILE" "swapon --show"

add_header "$MD_OUTPUT_FILE" "Disk Information"; echo '```' >> "$MD_OUTPUT_FILE"; run_and_append "$MD_OUTPUT_FILE" "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v 'loop'"; echo '```' >> "$MD_OUTPUT_FILE"
add_header "$TXT_OUTPUT_FILE" "STORAGE (BLOCKS)"; run_and_append "$TXT_OUTPUT_FILE" "lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,UUID"
add_header "$TXT_OUTPUT_FILE" "FILESYSTEM USAGE (df)"; run_and_append "$TXT_OUTPUT_FILE" "df -hT -x squashfs -x tmpfs -x devtmpfs"

add_header "$MD_OUTPUT_FILE" "GPU Information"; echo '```' >> "$MD_OUTPUT_FILE"; run_and_append "$MD_OUTPUT_FILE" "lspci | grep -i 'VGA compatible controller' || echo 'No VGA device via lspci.'" ; echo '```' >> "$MD_OUTPUT_FILE"
add_header "$TXT_OUTPUT_FILE" "GPU (lspci)"; run_and_append "$TXT_OUTPUT_FILE" "lspci -nnk | grep -i -A3 \"VGA\" || echo 'No VGA device details via lspci.'"

add_header "$MD_OUTPUT_FILE" "Hardware Summary (inxi)"; echo '```' >> "$MD_OUTPUT_FILE"; run_and_append "$MD_OUTPUT_FILE" "inxi -Fxzc0 || echo 'inxi command failed or not found.'" ; echo '```' >> "$MD_OUTPUT_FILE"
add_header "$TXT_OUTPUT_FILE" "HARDWARE (inxi)"; run_and_append "$TXT_OUTPUT_FILE" "inxi -Fxxxzc0 || echo 'inxi command failed or not found.'"

# --- Network, Devices, and Software ---
add_header "$TXT_OUTPUT_FILE" "NETWORK (PRIVACY-ENHANCED)"; run_and_append "$TXT_OUTPUT_FILE" "ip -br link | awk '{print \$1, \"(\" \$2 \")\"}'; echo; ip route show default; echo; echo 'DNS: See /etc/resolv.conf'"
add_header "$TXT_OUTPUT_FILE" "PCI DEVICES"; run_and_append "$TXT_OUTPUT_FILE" "lspci -tvnn"
add_header "$TXT_OUTPUT_FILE" "USB DEVICES"; run_and_append "$TXT_OUTPUT_FILE" "lsusb -tv"
add_header "$TXT_OUTPUT_FILE" "KERNEL MODULES"; run_and_append "$TXT_OUTPUT_FILE" "lsmod"

# --- Software Configuration ---
add_header "$TXT_OUTPUT_FILE" "INSTALLED PACKAGES (Arch Linux - Explicitly Installed, Top 500)"
run_and_append "$TXT_OUTPUT_FILE" "pacman -Qeq | head -n 500"

add_header "$TXT_OUTPUT_FILE" "ENABLED SYSTEMD SERVICES"
run_and_append "$TXT_OUTPUT_FILE" "systemctl list-unit-files --state=enabled"

# --- Completion ---
echo -e "\nReport generation complete."
echo "Markdown report: $MD_OUTPUT_FILE"
echo "Detailed text report: $TXT_OUTPUT_FILE"
exit 0
