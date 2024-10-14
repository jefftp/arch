#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. /root/install/99-options.sh

# Configure hostname
hostnamectl hostname "$HOSTNAME"

# Configure NTP time sync and timezone
timedatectl set-ntp true
timedatectl set-timezone "$TIMEZONE"

# Configure Locale
sed --in-place '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen

cat >> /etc/locale.conf << _EOF_
LANG=en_US.UTF-8
_EOF_

cat >> /etc/vconsole.conf << _EOF_
KEYMAP=us
FONT="$CONSOLE_FONT"
_EOF_

# Setup networking
pacman --sync --noconfirm networkmanager
systemctl enable systemd-resolved.service
systemctl enable NetworkManger.service

# Setup filesystem tools
pacman --sync --noconfirm btrfs-progs dosfstools exfatprogs e2fsprogs

# Setup manual pages
pacman --sync --noconfirm man-db man-pages

# Setup basic tools
pacman --sync --noconfirm vim git curl

# Install the bootloader
bootctl install

# Grab the partition UUID for the root partition
ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT"})

# Configure the primary bootloader config
cat > /boot/loader/entries/arch.conf << _EOF_
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
_EOF_

# Configure the fallback bootloader config
cat > /boot/loader/entries/arch-fallback.conf << _EOF_
title Arch Linux Fallback
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux-fallback.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
_EOF_

# Configure systemd-boot
cat > /boot/loader/loader.conf << _EOF_
default arch
timeout 5
_EOF_
