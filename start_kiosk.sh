#!/bin/sh

sleep 1
xrandr --output DSI-1 --rotate right
sleep 1
#exec python3 /opt/kiosk/test.py
exec /opt/kiosk/.venv/bin/python /opt/kiosk/kiosk_main.py
#exec python3 /opt/kiosk/kiosk_main.py
#exec  xterm
#startx /opt/kiosk/kiosk_main.py
