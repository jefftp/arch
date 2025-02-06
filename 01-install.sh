#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. ./options.conf

# Set the terminal font
setfont "$CONSOLE_FONT"

# Configure NTP time sync and timezone
timedatectl set-ntp true
timedatectl set-timezone "$TIMEZONE"

# Configure partitions
sgdisk --zap-all "$INSTALL_DISK"
sgdisk --new=1::+1G --typecode=1:ef00 --change-name=1:'EFI System Partition' "$INSTALL_DISK"
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'Root Partition' "$INSTALL_DISK"

# Format BTRFS partition and mount it
mkfs.btrfs "$ROOT"
mount "$ROOT" /mnt

# Create BTRFS subvolumes and umount the BTRFS partition
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# Mount BTRFS subvolumes
mount --options compress-force=zstd:1,noatime,subvol=@ "$ROOT" /mnt
mkdir --parents /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}
mount --options compress-force=zstd:1,noatime,nodev,nosuid,subvol=@home "$ROOT" /mnt/home
mount --options compress-force=zstd:1,noatime,nodev,nosuid,noexec,subvol=@log "$ROOT" /mnt/var/log
mount --options compress-force=zstd:1,noatime,nodev,nosuid,noexec,subvol=@pkg "$ROOT" /mnt/var/cache/pacman/pkg
mount --options compress-force=zstd:1,noatime,nodev,nosuid,noexec,subvol=@.snapshots "$ROOT" /mnt/.snapshots

# Format and mount boot partition
mkfs.fat -F 32 "$BOOT"
mount --options fmask=0077,dmask=0077 "$BOOT" /mnt/boot

# Setup the mirror list
reflector --country us --age 72 --protocol https --latest 20 --fastest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Enable additional pacman options in /etc/pacman.conf
sed --in-place '/ParallelDownloads/s/^#//' /etc/pacman.conf
sed --in-place '/Color/s/^#//' /etc/pacman.conf
sed --in-place '/VerbosePkgLists/s/^#//' /etc/pacman.conf

# Bootstrap the system
pacstrap -K /mnt base base-devel \
 linux-zen linux-zen-headers linux-firmware \
 amd-ucode \
 terminus-font \
 btrfs-progs dosfstools exfatprogs \
 iwd networkmanager \
 git sed zsh \
 reflector \
 snapper snap-pac \
 zram-generator

# Generate the filesystem table (fstab)
genfstab -U /mnt >> /mnt/etc/fstab

# Copy pacman configuration to new system
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Setup pacman hooks to copy /boot to /.bootbackup during upgrades
mkdir /mnt/etc/pacman.d/hooks
cp ./configs/pacman-bootbackup_pre.hook /mnt/etc/pacman.d/hooks/95-bootbackup_pre.hook
cp ./configs/pacman-bootbackup_post.hook /mnt/etc/pacman.d/hooks/95-bootbackup_post.hook

# Copy snapper config
cp ./configs/snapper-config-root /mnt/etc/snapper/configs/root
sed --in-place 's/SNAPPER_CONFIGS=""/SNAPPER_CONFIGS="root"/' /mnt/etc/conf.d/snapper

# Copy scripts to /mnt/usr/share/install-scripts/
cp --recursive . /mnt/usr/share/install-scripts/

# Change root to the new system and execute the configure.sh script
arch-chroot /mnt /usr/share/install-scripts/02-configure.sh

# End of install reminders
cat << _EOF_
+----------------------------------------------------------------------+
|  Base installation completed.                                        |
|                                                                      |
|  Additional Steps:                                                   |
|    1. Reboot.                                                        |
|    2. Run '/usr/share/install-scripts/03-post-install.sh' to run     |
|       post-installation setup.                                       |
+----------------------------------------------------------------------+
_EOF_
