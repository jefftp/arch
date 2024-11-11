#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. /root/install/99-options.sh

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

# Setup sudo to allow users in group 'wheel' to execute any command
sed --in-place '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

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

# Setup pacman hooks to copy /boot to /.bootbackup during upgrades
cp configs/pacman-bootbackup_pre.hook /etc/pacman.d/hooks/95-bootbackup_pre.hook
cp configs/pacman-bootbackup_post.hook /etc/pacman.d/hooks/95-bootbackup_post.hook

# Copy snapper config
cp configs/snapper-config-root /etc/snapper/configs/root

# End of install reminders
cat << _EOF_
+----------------------------------------------------------------------+
|  Base installation completed.                                        |
|                                                                      |
|  Additional Steps:                                                   |
|    1. Use 'passwd' to set a root password.                           |
|    2. Use 'passwd $USERNAME' to set a password for the $USERNAME     |
|       account.                                                       |
|    3. Reboot.                                                        |
|    4. Run '/usr/share/install-scripts/03-post-install.sh' to run     |
|       post-installation setup.                                       |
+----------------------------------------------------------------------+
_EOF_
