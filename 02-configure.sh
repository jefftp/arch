#!/bin/sh -e

# Load configuration options
. ./99-options.sh

# Set the root password
passwd

# Configure hostname
echo "$HOSTNAME" > /etc/hostname

# Configure timezone
ln --symbolic --force "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Configure Locale
sed --in-place '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo FONT="$CONSOLE_FONT" > /etc/vconsole.conf


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
cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
EOF

# Configure the fallback bootloader config
cat <<EOF > /boot/loader/entries/arch-fallback.conf
title Arch Linux Fallback
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux-fallback.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
EOF

# Configure systemd-boot
cat <<EOF > /boot/loader/loader.conf
default arch
timeout 5
EOF
