#!/bin/sh

# Exit on script error
set -e

# Load options
. ./options.conf

# Create .automount file for backup repo
cat <<_EOF_
[Unit]
Description=Automount Backup Repository

[Automount]
Where=${BACKUP_MOUNTPOINT}
TimeoutIdleSec=5min
_EOF_
