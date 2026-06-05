#!/usr/bin/env bash
set -euo pipefail
# Repos required before running (see scripts/setup-repos.sh):
#   docker-ce + plugins:     download.docker.com
#   gh:                      cli.github.com
#   nvidia-container-toolkit: nvidia.github.io
#   tailscale:               pkgs.tailscale.com/stable/ubuntu
#
# Desktop-only repos (setup-repos.sh, skipped on server):
#   code:                    packages.microsoft.com
#   firefox:                 packages.mozilla.org
#   google-chrome-stable:    dl.google.com
#   mattermost-desktop:      deb.packages.mattermost.com
#   signal-desktop:          updates.signal.org
#
# Desktop-only .deb downloads (see scripts/install-deb-apps.sh):
#   obsidian, zoom

DIR="$(dirname "$0")"
xargs sudo apt-get install -y < "$DIR/apt.txt"

if [[ "${PROFILE:-desktop}" == "desktop" ]]; then
    xargs sudo apt-get install -y < "$DIR/apt-desktop.txt"
fi
