#!/usr/bin/env bash
set -euo pipefail

# Install apps distributed as direct .deb downloads (no apt repo available).
# Idempotent — skips apps already installed.

install_deb() {
    local name="$1" url="$2"
    if dpkg -l "$name" &>/dev/null; then
        echo "  [skip] ${name} already installed"
        return
    fi
    echo "  [install] ${name}"
    local tmp
    tmp=$(mktemp --suffix=.deb)
    curl -fsSL "$url" -o "$tmp"
    sudo dpkg -i "$tmp"
    sudo apt-get install -f -y  # resolve any missing deps
    rm "$tmp"
}

if [[ "${PROFILE:-desktop}" != "desktop" ]]; then
    echo "  [skip] .deb apps — server profile"
    exit 0
fi

echo "==> Installing .deb apps..."

# Obsidian — latest release from GitHub
OBSIDIAN_VERSION=$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
install_deb "obsidian" \
    "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb"

# Zoom
install_deb "zoom" "https://zoom.us/client/latest/zoom_amd64.deb"

echo "==> Done."
