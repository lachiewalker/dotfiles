#!/usr/bin/env bash
set -euo pipefail

snap install glab --channel=latest/stable
snap install nordvpn --channel=latest/stable

if [[ "${PROFILE:-desktop}" == "desktop" ]]; then
    snap install gimp --channel=latest/stable
    snap install insomnia --channel=latest/stable
    snap install plex-desktop --channel=latest/stable
    snap install spotify --channel=latest/stable
    snap install steam --channel=latest/stable
    snap install thunderbird --channel=latest/stable
fi
