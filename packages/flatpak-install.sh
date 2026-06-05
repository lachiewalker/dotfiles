#!/usr/bin/env bash
set -euo pipefail

if [[ "${PROFILE:-desktop}" != "desktop" ]]; then
    echo "  [skip] flatpak apps — server profile"
    exit 0
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
xargs flatpak install -y flathub < "$(dirname "$0")/flatpak.txt"
