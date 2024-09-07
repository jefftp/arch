#!/usr/bin/env bash

# Load configuration options
OPT_INSTALL_DISK=/dev/sda
OPT_BOOT_PART=${OPT_INSTALL_DISK}1
OPT_ROOT_PART=${OPT_INSTALL_DISK}2
OPT_MOUNT_OPTIONS="compress-force=zstd:1,noatime"

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
sgdisk --zap-all {$OPT_INSTALL_DISK}
sgdisk --new=1::+1G --typecode=1:ef00 --change-name=1:'EFI System Partition' {$OPT_INSTALL_DISK}
sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:'Root Partition' {$OPT_INSTALL_DISK}


# Format BTRFS partition and mount it
mkfs.btrfs ${OPT_ROOT_PART}
mount ${OPT_ROOT_PART} /mnt

# Create BTRFS subvolumes and umount the BTRFS partition
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# Mount BTRFS subvolumes
mount -o ${OPT_MOUNT_OPTIONS},subvol=@ ${OPT_ROOT_PART} /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg}
mount -o ${OPT_MOUNT_OPTIONS},subvol=@home ${OPT_ROOT_PART} /mnt/home
mount -o ${OPT_MOUNT_OPTIONS},subvol=@log ${OPT_ROOT_PART} /mnt/var/log
mount -o ${OPT_MOUNT_OPTIONS},subvol=@pkg ${OPT_ROOT_PART} /mnt/var/cache/pacman/pkg
mount -o ${OPT_MOUNT_OPTIONS},subvol=@home ${OPT_ROOT_PART} /mnt/.snapshots

# Format and mount boot partition
mkfs.fat -F 32 ${OPT_BOOT_PART}
mount ${OPT_BOOT_PART} /mnt/boot

# Setup the mirror list
reflector --country us --age 48 --protocol https --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Bootstrap the system
pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode terminus-font

# Generate the filesystem table (fstab)
genfstab -U /mnt >> /mnt/etc/fstab

# Install the bootloader
bootctl --root=/mnt install

# Grab the partition UUID for the root partition
ROOT_UUID=$(blkid -s PARTUUID -o value ${OPT_ROOT_PART})

# Configure the primary bootloader config
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
EOF

# Configure the fallback bootloader config
cat <<EOF > /mnt/boot/loader/entries/arch-fallback.conf
title Arch Linux Fallback
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux-fallback.img
options root=PARTUUID=${ROOT_UUID} rootflags=subvol=@ rw
EOF

# Configure systemd-boot
cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
EOF

# Copy mirrorlist to new system
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Copy the configure script to new system
cp ./02-configure.sh /mnt/root/

# Change root to the new system
arch-chroot /mnt /root/02-configure.sh
