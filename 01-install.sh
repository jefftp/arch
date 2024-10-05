#!/usr/bin/env bash

# Load configuration options
source ./99-options.sh

# Set the terminal font
setfont ter-v18n

# Partition Scheme
# | Device    | filesystem | space     |
# | --------- | ---------- | --------- |
# | /dev/sda1 | fat32      | 1G        |
# | /dev/sda2 | btrfs      | remaining |

# Mount Scheme
# | Mount Point           | Device          |
# | --------------------- | --------------- |
# | /boot                 | /dev/sda1       |
# | /                     | /dev/sda2/@     |
# | /home                 | /dev/sda2/@home |
# | /var/log              | /dev/sda2/@log  |
# | /var/cache/pacman/pkg | /dev/sda2/@pkg  |

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
mount -o compress-force=zstd:1,noatime,subvol=@ "$ROOT" /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}
mount -o compress-force=zstd:1,noatime,subvol=@home "$ROOT" /mnt/home
mount -o compress-force=zstd:1,noatime,subvol=@log "$ROOT" /mnt/var/log
mount -o compress-force=zstd:1,noatime,subvol=@pkg "$ROOT" /mnt/var/cache/pacman/pkg
mount -o compress-force=zstd:1,noatime,subvol=@home "$ROOT" /mnt/.snapshots

# Format and mount boot partition
mkfs.fat -F 32 "$BOOT"
mount "$BOOT" /mnt/boot

# Setup the mirror list
reflector --country us --age 72 --protocol https --latest 20 --fastest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Bootstrap the system
pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode terminus-font

# Generate the filesystem table (fstab)
genfstab -U /mnt >> /mnt/etc/fstab

# Copy mirrorlist to new system
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Change root to the new system
arch-chroot /mnt ./02-configure.sh
