#!/bin/sh

# Exit on script error
set -e

# Install paru AUR helper
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg --syncdeps --install --noconfirm
