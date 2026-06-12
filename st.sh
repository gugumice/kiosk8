#!/bin/sh
sleep 1

export XAUTHORITY=/home/pi/.Xauthority


printf "Launching xinit"
/usr/bin/xinit /opt/kiosk/start_kiosk.sh
printf "END Launching xinit"

