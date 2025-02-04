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

# Remove the leading / from the mount path
BACKUP_SYSTEMD_UNIT="${BACKUP_MOUNTPATH#/}"

# Convert / to -
BACKUP_SYSTEMD_UNIT=$(echo "$BACKUP_SYSTEMD_UNIT" | tr '/' '-')

# Create .mount file for backup repo
cat > "/etc/systemd/system/${BACKUP_SYSTEMD_UNIT}.mount" <<_EOF_
[Unit]
Description=Backup Repository
After=network-online.target
Wants=network-online.target

[Mount]
What=${SMB_PATH}
Where=${BACKUP_MOUNTPOINT}
Type=cifs
Options=credentials=/etc/rustic/smb-credentials,vers=3,nosuid,nodev,noexec,noatime,file_mode=0600,dir_mode=0700,iocharset=utf8
TimeoutSec=30

[Install]
WantedBy=multi-user.target
_EOF_

# Create .automount file for backup repo
cat > "/etc/systemd/system/${BACKUP_SYSTEMD_UNIT}.automount" <<_EOF_
[Unit]
Description=Automount Backup Repository

[Automount]
Where=${BACKUP_MOUNTPOINT}
TimeoutIdleSec=5min
_EOF_

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
