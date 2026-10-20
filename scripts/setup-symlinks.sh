#!/usr/bin/env bash
set -euo pipefail

# fd-find installs as 'fdfind' on Ubuntu — symlink to 'fd' for standard usage
if [ -L "$HOME/.local/bin/fd" ]; then
    echo "  [skip] fd symlink already exists"
else
    echo "  [link] fd -> fdfind"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi

# Firefox uses ~/.mozilla/firefox instead of the XDG folder whenever it exists.
# Playwright's bundled Firefox creates that folder, which hides the real profile.
# Point it at the XDG folder so both paths reach the same profiles.
FIREFOX_XDG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox"
if [ -L "$HOME/.mozilla/firefox" ]; then
    echo "  [skip] ~/.mozilla/firefox symlink already exists"
elif [ -e "$HOME/.mozilla/firefox" ]; then
    echo "  [warn] ~/.mozilla/firefox is a real folder — move it away, then run this script again"
else
    echo "  [link] ~/.mozilla/firefox -> $FIREFOX_XDG_DIR"
    mkdir -p -m 700 "$HOME/.mozilla" "$FIREFOX_XDG_DIR"
    ln -s "$FIREFOX_XDG_DIR" "$HOME/.mozilla/firefox"
fi
