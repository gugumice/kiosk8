#!/bin/bash

USER="pi"
GROUP="kiosk"
WORK_DIR="/opt/kiosk/"
USER_DIR="/home/pi/"
# Disable bluetooth & WiFi

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (e.g. sudo $0)"
    exit 1
fi

systemctl disable bluetooth.service
systemctl disable hciuart.service

#Install minimal X server and dependencies
apt-get install python3-tk xserver-xorg xinit openbox -y
apt-get install xserver-xorg-legacy -y
apt-get install xterm -y
apt-get install x11-xserver-utils -y
apt-get install xinput -y
apt-get install fonts-dejavu fonts-liberation fonts-freefont-ttf fonts-noto-core-y
printf "Changing Xwrapper.config\n"
#sed -i 's/^allowed_users=console$/allowed_users=anybody\nneeds_root_rights=yes/' /etc/X11/Xwrapper.config
tee /etc/X11/Xwrapper.config >/dev/null <<'EOF'
allowed_users=anybody
needs_root_rights=yes
EOF

dpkg-reconfigure xserver-xorg-legacy
printf "Changing Xwrapper.config... done\n"

#Install tkinter & stuff
apt-get install python3-tk -y
apt-get install python3-pil.imagetk -y
printf "Installing tkinter & dependencies... done\n"

apt-get install python3-pip -y
sed -i '/^\[global\]$/a break-system-packages = true' /etc/pip.conf
printf "Installing pip & configuring... done\n"

apt-get install gcc python3-dev libcups2-dev cups cups-bsd -y
sleep 1
cupsctl --remote-admin --remote-any
usermod -aG lpadmin $USER
usermod -aG lp $USER
#Disable CUPS-browsed
./change_cups-browsed.sh
sleep 1
service cups restart
printf "Installing & configuring CUPS... done\n"

#Rotate WaveShare display, set touchscreen rotation
./touchpad_rules.sh
printf "Setting touchpad... done\n"
./update_config.sh "/boot/firmware/config.txt"
printf "Updating config.txt... done\n"

#Set up watchdog
addgroup watchdog
usermod -aG watchdog "${USER}"
printf 'KERNEL=="watchdog", MODE="0660", OWNER="pi", GROUP="watchdog"\n' > /etc/udev/rules.d/60-watchdog.rules
#Chown pi:kiosk /dev/watchdog
printf "Configuring watchdog... done\n"

#Install Python dependencies in virtual environment
apt-get install python3-venv -y
python3 -m venv --system-site-packages "${WORK_DIR}.venv"
source .venv/bin/activate
pip3 install customtkinter
pip3 install pillow
pip3 install pyserial
pip3 --no-input install pycups

#Setting timezone & logs"
timedatectl set-timezone Europe/Riga
printf "Setting logfiles\n"
touch "${WORK_DIR}kiosk.log" 
./make_logdirs.sh "/var/log/kiosk/kiosk.log"
ln -s "${WORK_DIR}kiosk.log" "${USER_DIR}kiosk.log"
ln "${WORK_DIR}firstboot.service" "/etc/systemd/system/firstboot.service"
ln "${WORK_DIR}kiosk.service" "/etc/systemd/system/kiosk.service"
systemctl enable firstboot.service
