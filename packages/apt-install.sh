#!/usr/bin/env bash
set -euo pipefail
# These packages require external repos added before running (see scripts/setup-repos.sh):
#   code:                    packages.microsoft.com
#   docker-ce + plugins:     download.docker.com
#   firefox:                 packages.mozilla.org  (Ubuntu apt version is a snap redirector)
#   gh:                      cli.github.com
#   google-chrome-stable:    dl.google.com
#   mattermost-desktop:      deb.packages.mattermost.com
#   nvidia-container-toolkit: nvidia.github.io
#   signal-desktop:          updates.signal.org (uses 'xenial' distro string — intentional)
#   tailscale:               pkgs.tailscale.com/stable/ubuntu
#
# These require scripted .deb downloads (see scripts/install-deb-apps.sh):
#   obsidian, zoom
xargs sudo apt-get install -y < "$(dirname "$0")/apt.txt"
