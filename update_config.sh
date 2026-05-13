#!/bin/bash

set -e

CONFIG="/boot/firmware/config.txt"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: $CONFIG not found"
    exit 1
fi

echo "Backing up config.txt..."
sudo cp "$CONFIG" "${CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"

echo "Updating config.txt..."

# Replace dtoverlay=vc4-kms-dsi-7inch
sudo sed -i \
    's/^dtoverlay=vc4-kms-dsi-7inch$/dtoverlay=vc4-kms-v3d\ndtoverlay=waveshare-43inch-dsi\nmax_framebuffers=2/' \
    "$CONFIG"

# Comment out disable_fw_kms_setup=1 if not already commented
sudo sed -i \
    's/^disable_fw_kms_setup=1$/#disable_fw_kms_setup=1/' \
    "$CONFIG"

echo
echo "Updated $CONFIG successfully."
