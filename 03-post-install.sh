#!/bin/sh

# Exit on script error
set -e

# Enable network services
systemctl enable --now systemd-resolved.service
systemctl enable --now NetworkManager.service

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

systemctl enable --now reflector.timer

# Enable snapper cleanup process
systemctl enable --now snapper-cleanup.timer
