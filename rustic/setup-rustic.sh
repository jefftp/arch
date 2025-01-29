#!/bin/sh
# Configure daily backups with Rustic to an SMB fileshare

# Exit on script error
set -e

# Make sure we're running as root
if ! [ $(id -u) = 0 ]; then
  echo 'ERROR: This script requires root permissions.'
  exit 1
fi

# Specify the SMB configuration here
SMB_USERNAME='backup-user'
SMB_PASSWORD='backup-password'
SMB_DOMAIN='WORKGROUP'
SMB_PATH='//nas/share'

# ----------------------------------------- #
# --- No changes needed below this line --- #
# ----------------------------------------- #

# Set permissions for new files so they are only accessible by root
umask 077

# Create config and repo mount point directories
mkdir /etc/rustic /mnt/backup

# Copy the Rustic configuration profile and set permissions
cp rustic.toml /etc/rustic/
chmod 600 /etc/rustic/rustic.toml

# Create the SMB credential file
cat > /etc/rustic/smb-credentials <<_EOF_
username=${SMB_USERNAME}
password=${SMB_PASSWORD}
_EOF_

# Create a random 32 character password for the backup repo password
cat /dev/urandom | tr -dc [:alnum:] | head -c32 > /etc/rustic/repo-credentials

# Update FSTAB with entry for /mnt/backup
cat >> /etc/fstab <<_EOF_
# /mnt/backup
${SMB_PATH} /mnt/backup cifs rw,credentials=/etc/rustic/smb-credentials,vers=3,nosuid,nodev,noexec,noatime,file_mode=0600,dir_mode=0700,iocharset=utf8,x-system.automount,x-systemd.mount-timeout=30,x-systemd.idle-timeout=300,_netdev 0 0
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
