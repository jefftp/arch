#!/bin/sh

# Exit on script error
set -e

# Load options
. ./options.conf

# Create .mount file for backup repo
cat <<_EOF_
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
