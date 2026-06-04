#!/usr/bin/env bash
# Install Gogh — GNOME Terminal color scheme installer
# https://gogh-co.github.io/Gogh/
# Run interactively to browse and install additional themes.
# Existing themes are already captured in gnome/terminal-profiles.ini
# and restored via gnome/restore.sh — only run this for new themes.
set -euo pipefail

bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Gogh-Co/Gogh/master/gogh.sh)"
