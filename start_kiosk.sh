#!/bin/sh
sleep 1
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
xset s off
xset s noblank
xset -dpms
xrandr --output DSI-1 --rotate right
sleep 1
exec /opt/kiosk/.venv/bin/python /opt/kiosk/kiosk_main.py

