#!/bin/sh
xrandr --output DSI-1 --rotate right
sleep 1
DISPLAY=:0 xset -dpms
exec python3 /opt/kiosk/test.py
#exec  xterm
