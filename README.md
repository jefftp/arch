# Arch Installer for JeffTP

This is a simple set of scripts for installing Arch linux from ISO.

Options can be configured in the 99-options.sh file, which is sourced by the other scripts.

## Pulling scripts from GitHub

`pacman -Sy git`
`git clone https://github.com/jefftp/arch.git`

## Partition Scheme

| Device    | filesystem | space     |
| --------- | ---------- | --------- |
| /dev/sda1 | fat32      | 1G        |
| /dev/sda2 | btrfs      | remaining |

## Mount Scheme

| Mount Point           | Device          |
| --------------------- | --------------- |
| /boot                 | /dev/sda1       |
| /                     | /dev/sda2/@     |
| /home                 | /dev/sda2/@home |
| /var/log              | /dev/sda2/@log  |
| /var/cache/pacman/pkg | /dev/sda2/@pkg  |
