#!/bin/sh
xrandr --output DSI-1 --rotate right
sleep 1
exec python3 /opt/kiosk/test.py
#exec  xterm
