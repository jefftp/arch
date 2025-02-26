#!/bin/sh

# Exit on script error
set -e

# Load options
. ./options.conf

# Create the rustic configuration profile
cat <<_EOF_
[global]
log-level = "info"
log-file = "/var/log/rustic.log"

[repository]
repository = "${BACKUP_MOUNTPOINT}"
password-file = "/etc/rustic/repo-credentials"
no-cache = true

[backup]
globs = [
  "!/home/*/.cache/**",
  "!/home/*/.mozilla/firefox/*/storage/default/**",
  "!/root/.cache/**",
]

[[backup.snapshots]]
sources = [
  "/home",
  "/root",
  "/etc",
]

[forget]
keep-daily = 14
keep-weekly = 4
keep-monthly = 3
prune = true
_EOF_
