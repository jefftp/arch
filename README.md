# Arch Installer for JeffTP

This is a simple set of scripts for installing Arch linux from the Arch Install ISO. The focus is to automate the steps you might manually step through when installing Arch Linux. The scripts are intentionally written to be straight-forward and simple.

I consider these scripts useful for intermediate linux users who want more control than available in `archinstall`. If you're new to linux, you will probably find `archinstall` makes it easier to get up and running quickly.

If you use these scripts as part of your installation automation adventure, I'd appreciate seeing what changes you made. I might find them useful! There's no requirements to share credit or changes, but I'd appreciate either.

Options can be configured in the `99-options.sh` file, which is sourced by the other scripts.

You need to get networking up and running prior to running any of these scripts.

## Pulling scripts from GitHub

`pacman -Sy git`
`git clone https://github.com/jefftp/arch.git`

## Figuring out your storage devices

Use `lsblk` to list block devices on the system. The device name will be prefixed with `/dev/`.

## Running the installation scripts

First, update the variables in `99-options.sh` to change any options such as the install disk or timezone.

Next run `01-install.sh`. This will call `02-configure.sh` as part of the installation.

Once the installation completes successfully, you'll get a reminder to set a root password, reboot, and then run `03-post-install.sh` to finish the installation.

## Storage Notes

### Partition Scheme

The script `01-install.sh` partitions a single drive based on the variable `INSTALL_DISK` in the script `99-options.sh`.

| Device    | filesystem | space     |
| --------- | ---------- | --------- |
| /dev/sda1 | fat32      | 1G        |
| /dev/sda2 | btrfs      | remaining |

### Mount Scheme

The sub-volumes for BTRFS are based on the sub-volume scheme used by the `archinstall` script. The @.snapshots sub-volume is intended to be used with `snapper` to create storage snapshots.

| Mount Point           | Device                |
| --------------------- | --------------------- |
| /boot                 | /dev/sda1             |
| /                     | /dev/sda2/@           |
| /home                 | /dev/sda2/@home       |
| /var/log              | /dev/sda2/@log        |
| /var/cache/pacman/pkg | /dev/sda2/@pkg        |
| /.snapshots           | /dev/sda2/@.snapshots |
