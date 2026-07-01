#!/usr/bin/env bash

set -euo pipefail

# CMDLINE_FILE="/boot/firmware/cmdline.txt"
CMDLINE_FILE="/home/pi/cmdline.txt"
BACKUP_FILE="${CMDLINE_FILE}.$(date +%Y%m%d-%H%M%S).bak"

PARAMS="consoleblank=0"

# Verify the file exists
if [[ ! -f "$CMDLINE_FILE" ]]; then
    echo "Error: $CMDLINE_FILE does not exist." >&2
    exit 1
fi

# Create a backup
cp -p "$CMDLINE_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Read current contents
current=$(<"$CMDLINE_FILE")

# Append parameters only if not already present
if [[ "$current" == *"$PARAMS"* ]]; then
    echo "Parameters already present. No changes made."
else
    printf '%s %s\n' "$current" "$PARAMS" > "$CMDLINE_FILE"
    echo "Parameters appended successfully."
fi
