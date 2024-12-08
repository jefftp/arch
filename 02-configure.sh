#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. /usr/share/install-scripts/99-options.sh

# Configure timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Configure Locale
sed --in-place '/en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen

cat >> /etc/locale.conf << _EOF_
LANG=en_US.UTF-8
_EOF_

cat >> /etc/vconsole.conf << _EOF_
KEYMAP=us
FONT="$CONSOLE_FONT"
_EOF_

# Configure hostname
echo "$HOSTNAME" > /etc/hostname

# Create a user with membership in wheel
useradd --create-home --groups wheel --shell /usr/bin/zsh "$USERNAME"

# Install the bootloader
bootctl install

# Grab the partition UUID for the root partition
ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT")

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

# Allow users in group 'wheel' to execute any command without a password
sed --in-place '/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /etc/sudoers

# Install paru using an normal user as required by makepkg
/usr/bin/runuser -u "$USERNAME" -- /usr/share/install-scripts/03-install-paru.sh

# Limit paru to AUR packages
sed --in-place '/AurOnly/s/^#//' /mnt/etc/paru.conf

# Remove no password sudo enabled earlier
sed --in-place '/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers

# Allow users in group 'wheel' to execute any command; with their password
sed --in-place '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers


# Set the root password
echo
echo "Setting the password for root..."
passwd

# Set the password for the user
echo
echo "Setting the password for ${USERNAME}..."
passwd "$USERNAME"
