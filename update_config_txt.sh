#!/bin/bash

set -euo pipefail

FILE="/boot/firmware/config.txt"
BACKUP="${FILE}.bak.$(date +%Y%m%d_%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root, e.g. sudo $0"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "Error: $FILE does not exist."
    exit 1
fi

cp "$FILE" "$BACKUP"
echo "Backup created: $BACKUP"

python3 - "$FILE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

block = """# Enable DRM VC4 V3D driver
#dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-7inch
max_framebuffers=2
display_rotate=1 #1：90；2: 180； 3: 270"""

lines = text.splitlines()

# Remove existing related lines to avoid duplicates
remove_prefixes = (
    "# Enable DRM VC4 V3D driver",
    "dtoverlay=vc4-kms-v3d",
    "#dtoverlay=vc4-kms-v3d",
    "dtoverlay=vc4-kms-dsi-7inch",
    "max_framebuffers=2",
    "display_rotate=",
)

new_lines = []
for line in lines:
    stripped = line.strip()
    if any(stripped.startswith(prefix) for prefix in remove_prefixes):
        continue
    new_lines.append(line)

# Keep one blank line before appending block if needed
while new_lines and new_lines[-1].strip() == "":
    new_lines.pop()

new_text = "\n".join(new_lines)
if new_text:
    new_text += "\n\n"
new_text += block + "\n"

path.write_text(new_text)
PY

echo "Updated $FILE"
echo "Done."
