#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. /usr/share/install-scripts/options.conf

# Configure timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Configure Locale
sed --in-place '/en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen

cat >>/etc/locale.conf <<_EOF_
LANG=en_US.UTF-8
_EOF_

cat >>/etc/vconsole.conf <<_EOF_
KEYMAP=us
FONT="$CONSOLE_FONT"
_EOF_

# Configure hostname
echo "$HOSTNAME" >/etc/hostname

# Add sysctl settings
cat >/etc/sysctl.d/80-networking.conf <<_EOF_
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
_EOF_

cat >/etc/sysctl.d/90-gaming.conf <<_EOF_
kernel.split_lock_mitigate=0
vm.max_map_count=2147483642
_EOF_

# Enable the multilib repository
sed --in-place "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Install essential commandline utilities
pacman --sync --refresh --noconfirm \
  bat less \
  curl wget rsync openssh \
  man-db man-pages \
  lsd fd fzf starship tmux \
  fastfetch btop \
  chezmoi rustic \
  unrar unzip zip 7zip \
  neovim vim \
  uv

# Install GPU drivers and tools
pacman --sync --refresh --noconfirm \
  dkms nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils

# Install desktop environment and tools
pacman --sync --refresh --noconfirm \
  plasma sddm \
  pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse wireplumber \
  noto-fonts-emoji ttf-dejavu ttf-inconsolata-nerd \
  ark dolphin filelight geeqie kcalc kitty firefox steam \
  bluez bluez-utils \
  okular cups system-config-printer \
  gamemode lib32-gamemode \
  fuse2

# Create a user with membership in wheel
useradd --create-home --groups wheel,gamemode --shell /usr/bin/zsh "$USERNAME"

# Allow users in group 'wheel' to execute any command; with their password
sed --in-place '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

# Install the bootloader
bootctl install

# Grab the partition UUID for the root partition
ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT")

# Configure the primary bootloader config
cat >/boot/loader/entries/arch.conf <<_EOF_
title Arch Linux (linux-zen)
linux /vmlinuz-linux-zen
initrd /amd-ucode.img
initrd /initramfs-linux-zen.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
_EOF_

# Configure the fallback bootloader config
cat >/boot/loader/entries/arch-fallback.conf <<_EOF_
title Arch Linux Fallback (linux-zen)
linux /vmlinuz-linux-zen
initrd /amd-ucode.img
initrd /initramfs-linux-zen-fallback.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
_EOF_

# Configure systemd-boot
cat >/boot/loader/loader.conf <<_EOF_
default arch
timeout 5
_EOF_

# Set the root password
echo
echo "Setting the password for root..."
passwd

# Set the password for the user
echo
echo "Setting the password for ${USERNAME}..."
passwd "$USERNAME"
