#!/bin/sh

# Exit on script error
set -e

# Enable network services
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service

# Start services
systemctl start systemd-resolved.service
systemctl start NetworkManager.service

# Start NTP
timedatectl set-ntp true

# Setup ZRAM
cat > /etc/systemd/zram-generator.conf << _EOF_
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
_EOF_

systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service

# Setup reflector to automatically update mirrorlist
cat > /etc/xdg/reflector/reflector.conf << _EOF_
# Reflector configuration file for the systemd service.
--country us
--age 72
--protocol https
--latest 20
--fastest 5
--sort rate
--save /etc/pacman.d/mirrorlist
_EOF_

systemctl enable reflector.timer
systemctl start reflector.timer

# Setup sudo to allow users in group 'wheel' to execute any command
sed --in-place '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
