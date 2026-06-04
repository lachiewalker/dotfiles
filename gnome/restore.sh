#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$0")"

# Restore interface preferences (dark mode, clock format, etc.)
# Keys like gtk-theme/icon-theme are Yaru-specific — may not apply after an OS upgrade
dconf load /org/gnome/desktop/interface/ < "$DIR/interface.ini"

echo "GNOME preferences restored."
echo "Note: gtk-theme/icon-theme may need manual adjustment after a distro upgrade."
