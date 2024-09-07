#!/usr/bin/env bash

OPT_HOSTNAME="torment"
OPT_TIMEZONE="America/Chicago"

# Set the root password
passwd

# Configure hostname
echo ${OPT_HOSTNAME} > /etc/hostname

# Configure timezone
ln -sf /usr/share/zoneinfo/${OPT_TIMEZONE} /etc/localtime
hwclock --systohc

# Configure Locale
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo FONT=ter-v18n > /etc/vconsole.conf


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
