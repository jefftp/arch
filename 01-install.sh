#!/bin/sh

# Exit script on error
set -e

# Load configuration options
. ./99-options.sh

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
mount --options compress-force=zstd:1,noatime,subvol=@home "$ROOT" /mnt/home
mount --options compress-force=zstd:1,noatime,subvol=@log "$ROOT" /mnt/var/log
mount --options compress-force=zstd:1,noatime,subvol=@pkg "$ROOT" /mnt/var/cache/pacman/pkg
mount --options compress-force=zstd:1,noatime,subvol=@.snapshots "$ROOT" /mnt/.snapshots

# Format and mount boot partition
mkfs.fat -F 32 "$BOOT"
mount "$BOOT" /mnt/boot

# Setup the mirror list
reflector --country us --age 72 --protocol https --latest 20 --fastest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Enable additional pacman options in /etc/pacman.conf
sed --in-place '/ParallelDownloads/s/^#//' /etc/pacman.conf
sed --in-place '/Color/s/^#//' /etc/pacman.conf

# Bootstrap the system
xargs pacstrap -K /mnt < ./packages/base.txt

# Patch genfstab to correctly remove option subvolid from btrfs mounts
# when subvol option is present
pacman --sync --noconfirm patch
patch /usr/bin/genfstab < ./patches/fix-genfstab.diff

# Generate the filesystem table (fstab)
genfstab -U /mnt >> /mnt/etc/fstab

# Copy mirrorlist to new system
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Copy scripts to /mnt/root/install
mkdir /mnt/root/install
cp *.sh /mnt/root/install/

# Change root to the new system
arch-chroot /mnt /root/install/02-configure.sh
