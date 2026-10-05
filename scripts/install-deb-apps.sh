#!/usr/bin/env bash
set -euo pipefail

# Install apps distributed as direct .deb downloads (no apt repo available).
# Idempotent — skips apps already installed.

install_deb() {
    local name="$1" url="$2"
    if [[ "$(dpkg-query -W -f='${Status}' "$name" 2>/dev/null)" == "install ok installed" ]]; then
        echo "  [skip] ${name} already installed"
        return
    fi
    echo "  [install] ${name}"
    local tmp
    tmp=$(mktemp --suffix=.deb)
    curl -fsSL "$url" -o "$tmp"
    chmod 644 "$tmp"                 # apt's sandbox user needs to read it
    sudo apt-get install -y "$tmp"   # installs the .deb and its dependencies
    rm -f "$tmp"
}

echo "==> Installing .deb apps..."

# s5cmd — latest release from GitHub (not in the Ubuntu archive)
S5CMD_VERSION=$(curl -fsSL https://api.github.com/repos/peak/s5cmd/releases/latest \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
install_deb "s5cmd" \
    "https://github.com/peak/s5cmd/releases/download/v${S5CMD_VERSION}/s5cmd_${S5CMD_VERSION}_linux_amd64.deb"

if [[ "${CHEZMOI_PROFILE:-desktop}" != "desktop" ]]; then
    echo "  [skip] desktop .deb apps — server profile"
    exit 0
fi

# Obsidian — newest release that ships a .deb (some releases are mobile-only)
OBSIDIAN_URL=$(curl -fsSL "https://api.github.com/repos/obsidianmd/obsidian-releases/releases?per_page=20" \
    | grep -o '"browser_download_url": *"[^"]*_amd64\.deb"' \
    | head -n1 | cut -d'"' -f4)
if [[ -n "$OBSIDIAN_URL" ]]; then
    install_deb "obsidian" "$OBSIDIAN_URL"
else
    echo "  [skip] obsidian — no .deb found in recent releases"
fi

# Zoom
install_deb "zoom" "https://zoom.us/client/latest/zoom_amd64.deb"

# Minecraft (official launcher) — tarball; Mojang's .deb has dependencies newer Ubuntu no longer has
if [[ ! -x "$HOME/.local/opt/minecraft-launcher/minecraft-launcher" ]]; then
    echo "  [install] minecraft-launcher"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/share/applications"
    curl -fsSL https://launcher.mojang.com/download/Minecraft.tar.gz \
        | tar -xz -C "$HOME/.local/opt"
    ln -sf "$HOME/.local/opt/minecraft-launcher/minecraft-launcher" "$HOME/.local/bin/minecraft-launcher"
    cat > "$HOME/.local/share/applications/minecraft-launcher.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Minecraft Launcher
Exec=$HOME/.local/opt/minecraft-launcher/minecraft-launcher
Icon=minecraft
Categories=Game;
EOF
else
    echo "  [skip] minecraft-launcher already installed"
fi

echo "==> Done."
