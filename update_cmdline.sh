#!/bin/bash

set -euo pipefail

FILE="/boot/firmware/cmdline.txt"
BACKUP="${FILE}.bak.$(date +%Y%m%d_%H%M%S)"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (e.g. sudo $0)"
    exit 1
fi

# Check if the file exists
if [[ ! -f "$FILE" ]]; then
    echo "Error: $FILE does not exist."
    exit 1
fi

# Create a backup
cp "$FILE" "$BACKUP"
echo "Backup created: $BACKUP"

# Append consoleblank=0 if it's not already present
if grep -qw "consoleblank=0" "$FILE"; then
    echo "'consoleblank=0' is already present. No changes made."
else
    sed -i 's/$/ consoleblank=0/' "$FILE"
    echo "Added 'consoleblank=0' to $FILE"
fi

echo "Done."
