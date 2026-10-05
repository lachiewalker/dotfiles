#!/usr/bin/env bash
set -euo pipefail

snap install glab --channel=latest/stable

if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    snap install gimp --channel=latest/stable
    snap install insomnia --channel=latest/stable
    snap install plex-desktop --channel=latest/stable
    snap install spotify --channel=latest/stable
    snap install steam --channel=latest/stable
    snap install thunderbird --channel=latest/stable

    # Replace Ubuntu's Firefox snap with the Mozilla apt build (apt-desktop.txt).
    # Ubuntu's own 'firefox' deb is a snap wrapper with "snap" in its version string.
    if snap list firefox &>/dev/null \
        && dpkg-query -W -f='${Version}' firefox 2>/dev/null | grep -qv snap; then
        echo "  [remove] firefox snap (Mozilla apt build is installed)"
        sudo snap remove --purge firefox
    fi
fi
