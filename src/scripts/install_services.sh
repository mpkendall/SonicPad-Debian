#!/bin/bash

set -e

INSTALLER_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
SYSTEMD="/etc/systemd/system"
USER=$(whoami)


echo "Adding hostname to hosts"
sudo -- sh -c "echo '127.0.1.1 SonicPad' >> /etc/hosts"

# Install XFCE and LightDM for tablet desktop experience
echo "Installing XFCE and LightDM display manager"
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-goodies lightdm

# Enable LightDM to start at boot
sudo systemctl enable lightdm

# Optionally, set up autologin for the default user
DEFAULT_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$DEFAULT_USER" ]; then
	sudo mkdir -p /etc/lightdm/lightdm.conf.d
	echo -e "[Seat:*]\nautologin-user=$DEFAULT_USER" | sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf
fi

echo "Fixing networking..."
sudo -- sh -c "echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' > /etc/wpa_supplicant/wpa_supplicant.conf"
sudo usermod -aG netdev $USER

echo "Compiling brightness..."
sudo chown -R $USER /home/$USER/scripts
cd /home/$USER/scripts/resources/brightness
gcc -o brightness brightness.c
sudo mv brightness /bin/brightness

echo "Cleaning up cache"
sudo apt clean
sudo rm -rf /var/cache/apt/
sudo rm -rf ~/.cache

sudo update-ca-certificates
sudo c_rehash
