#!/bin/bash

set -e

INSTALLER_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
SYSTEMD="/etc/systemd/system"
USER=$(whoami)

echo "Adding hostname to hosts"
sudo -- sh -c "echo '127.0.1.1 SonicPad' >> /etc/hosts"

# Install XFCE and LightDM for tablet desktop experience
echo "Installing XFCE and tablet-friendly packages"
sudo apt-get update
sudo apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-terminal \
    lightdm \
    lightdm-gtk-greeter \
    onboard \
    firefox-esr \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    gvfs \
    gvfs-backends \
    network-manager-gnome \
    pulseaudio \
    pavucontrol \
    xserver-xorg-input-libinput \
    at-spi2-core

# Configure X11 for tablet/touchscreen
echo "Configuring X11 for touchscreen and proper display"
sudo mkdir -p /etc/X11/xorg.conf.d

# Create touchscreen input configuration
sudo tee /etc/X11/xorg.conf.d/40-libinput.conf > /dev/null <<EOF
Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Calibration" "0 800 0 480"
    Option "SwapAxes" "0"
    Option "InvertX" "0"
    Option "InvertY" "0"
EndSection

Section "InputClass"
    Identifier "libinput pointer catchall"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
EOF

# Copy and enhance the display configuration
echo "Setting up display configuration"
sudo cp /home/$USER/scripts/resources/xorg.conf /etc/X11/xorg.conf

# Enhance the xorg.conf for better tablet experience
sudo tee -a /etc/X11/xorg.conf > /dev/null <<EOF

Section "Screen"
    Identifier      "Default Screen"
    Device          "Allwinner R818 FBDEV"
    DefaultDepth    24
    SubSection "Display"
        Depth       24
        Modes       "800x480"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier      "Default Layout"
    Screen          "Default Screen"
EndSection
EOF

# Allow any user to start Xorg
echo "Configuring Xorg to allow any user to start X server"
sudo mkdir -p /etc/X11
echo -e "allowed_users=anybody\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config

# Enable LightDM to start at boot
sudo systemctl enable lightdm

# Configure autologin for tablet experience
DEFAULT_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$DEFAULT_USER" ]; then
    echo "Setting up autologin for $DEFAULT_USER"
    sudo mkdir -p /etc/lightdm/lightdm.conf.d
    sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$DEFAULT_USER
autologin-user-timeout=0
user-session=xfce
greeter-hide-users=false
EOF
fi

# Configure XFCE for tablet interface
echo "Configuring XFCE for tablet interface"
mkdir -p /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/$USER/.config/autostart

# Configure XFCE panel for touch interface
tee /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="48"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator"/>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="clock"/>
    <property name="plugin-6" type="string" value="actions"/>
  </property>
</channel>
EOF

# Configure window manager for tablet
tee /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default"/>
    <property name="title_font" type="string" value="Sans Bold 11"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="double_click_time" type="int" value="400"/>
    <property name="easy_click" type="string" value="Alt"/>
    <property name="focus_delay" type="int" value="250"/>
    <property name="focus_hint" type="bool" value="true"/>
    <property name="focus_new" type="bool" value="true"/>
    <property name="raise_delay" type="int" value="250"/>
    <property name="raise_on_click" type="bool" value="true"/>
    <property name="raise_on_focus" type="bool" value="false"/>
    <property name="raise_with_any_button" type="bool" value="true"/>
    <property name="mousewheel_rollup" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="false"/>
    <property name="snap_width" type="int" value="10"/>
    <property name="wrap_windows" type="bool" value="true"/>
    <property name="wrap_workspaces" type="bool" value="false"/>
  </property>
</channel>
EOF

# Set up desktop configuration for tablet
tee /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="2"/>
    <property name="size" type="uint" value="48"/>
  </property>
  <property name="desktop-menu" type="empty">
    <property name="show" type="bool" value="true"/>
  </property>
</channel>
EOF

# Create a tablet-friendly launcher script
mkdir -p /home/$USER/.config/autostart
tee /home/$USER/.config/autostart/tablet-setup.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Tablet Setup
Comment=Configure tablet interface on startup
Exec=/home/$USER/scripts/tablet-startup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Create the tablet startup script
tee /home/$USER/scripts/tablet-startup.sh > /dev/null <<EOF
#!/bin/bash
# Tablet startup configuration

# Start onboard virtual keyboard when needed
#onboard &

# Set screen brightness to a comfortable level
sudo /bin/brightness -v 80

# Configure touchscreen if needed
# xinput --set-prop "TouchScreen" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1

# Disable screensaver for tablet use
xset s off
xset -dpms

# Set larger cursor for touch interface
xsetroot -cursor_name left_ptr
EOF

chmod +x /home/$USER/scripts/tablet-startup.sh

echo "Fixing networking..."
sudo -- sh -c "echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' > /etc/wpa_supplicant/wpa_supplicant.conf"
sudo usermod -aG netdev $USER

echo "Compiling brightness tool..."
sudo chown -R $USER /home/$USER/scripts
cd /home/$USER/scripts/resources/brightness
gcc -o brightness brightness.c
sudo mv brightness /bin/brightness

# Set proper permissions for user directories
chown -R $USER:$USER /home/$USER/.config

echo "Cleaning up cache"
sudo apt clean
sudo rm -rf /var/cache/apt/
sudo rm -rf ~/.cache

sudo update-ca-certificates
sudo c_rehash

echo "XFCE tablet setup complete!"
echo "The system will boot into XFCE desktop environment optimized for tablet use."