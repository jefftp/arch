#!/bin/sh

# Exit script on error
set -e

INSTALL_DISK="/dev/sda"
BOOT="${INSTALL_DISK}1"
ROOT="${INSTALL_DISK}2"

HOSTNAME="torment"
TIMEZONE="America/Chicago"

CONSOLE_FONT=ter-v18n
