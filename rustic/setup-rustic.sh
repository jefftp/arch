#!/bin/sh
# Configure daily backups with Rustic to an SMB fileshare

# Exit on script error
set -e

# Make sure we're running as root
if ! [ $(id -u) = 0 ]; then
  echo 'ERROR: This script requires root permissions.'
  exit 1
fi

# Load options
. ./options.conf

# Set permissions for new files so they are only accessible by root
umask 077

# Create config and repo mount point directories
mkdir /etc/rustic "$BACKUP_MOUNTPOINT"

# Create the SMB credential file
cat > /etc/rustic/smb-credentials <<_EOF_
username=${SMB_USERNAME}
password=${SMB_PASSWORD}
_EOF_

# Create a random 32 character password for the backup repo password
cat /dev/urandom | tr -dc [:alnum:] | head -c32 > /etc/rustic/repo-credentials

# Create rustic configuration file
( ./gen-rustic-config.sh ) > /etc/rustic/rustic.toml

# Convert $BACKUP_MOUNTPATH to BACKUP_SYSTEMD_UNIT
if [ -z "$BACKUP_MOUNTPATH" ] || [ "${BACKUP_MOUNTPATH#/}" = "$BACKUP_MOUNTPATH"]; then
  echo "ERROR: BACKUP_MOUNTPATH must be an absolute path." >&2
  exit 1
fi

# Remove the leading / from the mount path, and then convert "/" to "-"
BACKUP_SYSTEMD_UNIT="${BACKUP_MOUNTPATH#/}"
BACKUP_SYSTEMD_UNIT=$(echo "$BACKUP_SYSTEMD_UNIT" | tr '/' '-')

# Create .mount and .automount unit files for backup repo
( ./gen-mount-unit.sh ) > "/etc/systemd/system/${BACKUP_SYSTEMD_UNIT}.mount"
( ./gen-automount-unit.sh ) > "/etc/systemd/system/${BACKUP_SYSTEMD_UNIT}.automount"

# Copy service and timer unit files into place and set permissions
cp rustic-backup.{service,timer} /etc/systemd/system
chmod 644 /etc/systemd/system/rustic-backup.{service,timer}

# Reload the systemd config and remote-fs.target to load changes to fstab
systemctl daemon-reload
systemctl reload remote-fs.target

# Initialize the backup repo
rustic init

# Enable the backup timer
systemctl enable --now rustic-backup.timer
