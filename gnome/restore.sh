#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$0")"

# Restore interface preferences (dark mode, clock format, etc.)
# Keys like gtk-theme/icon-theme are Yaru-specific — may not apply after an OS upgrade
dconf load /org/gnome/desktop/interface/ < "$DIR/interface.ini"

# Never blank, lock or suspend on idle (install.sh also sets these at the start,
# before this script exists on disk, so the screen stays on during prompts)
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Ubuntu Dock: click an app icon to focus it, click again to minimize
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# Restore GNOME Terminal profiles (all 17 Gogh themes + Breeze default)
dconf load /org/gnome/terminal/ < "$DIR/terminal-profiles.ini"

# Install filmholes icon (required for G_RESOURCE_OVERLAYS in ~/.profile)
sudo cp "$DIR/filmholes.png" /usr/share/icons/filmholes.png

echo "GNOME preferences restored."
echo "Note: gtk-theme/icon-theme may need manual adjustment after a distro upgrade."
