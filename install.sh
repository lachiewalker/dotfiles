#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/lachiewalker/dotfiles.git"
NVM_VERSION="v0.40.4"
NODE_VERSION="22.14.0"
DOTFILES="$HOME/Projects/repos/dotfiles"

# bw CLI is a Node app that fails on IPv6 — force IPv4 for this entire script.
# ~/.bashrc sets this normally, but isn't sourced until after chezmoi apply.
export NODE_OPTIONS="--dns-result-order=ipv4first --no-network-family-autoselection"

# ── 0. Profile ─────────────────────────────────────────────────────────────────
if [[ -n "${CHEZMOI_PROFILE:-}" ]]; then
    echo "Using profile: ${CHEZMOI_PROFILE}"
else
    while true; do
        read -rp "Profile (desktop/server): " CHEZMOI_PROFILE
        case "$CHEZMOI_PROFILE" in
            desktop|server) break ;;
            *) echo "  Must be 'desktop' or 'server'." ;;
        esac
    done
fi
export CHEZMOI_PROFILE

# ── 1. git ─────────────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    sudo apt-get update -qq
    sudo apt-get install -y git
fi

# ── 2. chezmoi ─────────────────────────────────────────────────────────────────
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# ── 3. nvm + node (needed before bw CLI) ──────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "==> Installing nvm ${NVM_VERSION}..."
    CHEZMOI_PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    echo "==> Installing node ${NODE_VERSION}..."
    nvm install "$NODE_VERSION"
fi
nvm use "$NODE_VERSION"

# ── 4. Bitwarden CLI ───────────────────────────────────────────────────────────
if ! command -v bw &>/dev/null; then
    echo "==> Installing Bitwarden CLI..."
    npm install -g @bitwarden/cli
fi

# ── 5. Bitwarden login + unlock ────────────────────────────────────────────────
BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unauthenticated")
if [ "$BW_STATUS" = "unauthenticated" ]; then
    echo "==> Log in to Bitwarden:"
    bw login
fi
if [ -z "${BW_SESSION:-}" ]; then
    echo "==> Unlock Bitwarden vault:"
    BW_SESSION=$(bw unlock --raw)
    export BW_SESSION
fi

# ── 6. age ─────────────────────────────────────────────────────────────────────
if ! command -v age &>/dev/null; then
    echo "==> Installing age..."
    sudo apt-get install -y age
fi

# ── 7. age key from Bitwarden ──────────────────────────────────────────────────
if [ ! -f "$HOME/.age/key.txt" ]; then
    echo "==> Retrieving age key from Bitwarden (chezmoi/age-key)..."
    mkdir -p "$HOME/.age"
    chmod 700 "$HOME/.age"
    bw get notes "chezmoi/age-key" > "$HOME/.age/key.txt"
    chmod 600 "$HOME/.age/key.txt"
fi

# ── 8. Apply dotfiles ──────────────────────────────────────────────────────────
echo "==> Applying dotfiles..."
chezmoi init --apply --data "{\"profile\":\"${CHEZMOI_PROFILE}\"}" "$REPO"

# ── 9. apt repositories ────────────────────────────────────────────────────────
echo "==> Adding apt repositories..."
bash "$DOTFILES/scripts/setup-repos.sh"
sudo apt-get update -qq

# ── 10. packages ───────────────────────────────────────────────────────────────
echo "==> Installing packages..."
bash "$DOTFILES/scripts/install-packages.sh"

# ── 11. SSH keys ───────────────────────────────────────────────────────────────
echo "==> Generating SSH keys..."
bash "$DOTFILES/scripts/setup-ssh.sh"

# ── 12. Auth (gh, glab, SSH key registration) ─────────────────────────────────
echo "==> Setting up auth..."
bash "$DOTFILES/scripts/setup-auth.sh"

# ── 13. GNOME settings, terminal profiles, filmholes icon ─────────────────────
if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    echo "==> Restoring GNOME settings..."
    bash "$DOTFILES/gnome/restore.sh"
fi

# ── 14. Wallpapers and profile pictures ───────────────────────────────────────
if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    echo "==> Restoring pictures..."
    bash "$DOTFILES/Pictures/restore.sh"
fi

# ── 15. NVIDIA Docker runtime (skip if no GPU) ────────────────────────────────
if command -v nvidia-smi &>/dev/null; then
    echo "==> Configuring NVIDIA Docker runtime..."
    bash "$DOTFILES/scripts/setup-nvidia-docker.sh"
fi

# ── 16. Service logins ─────────────────────────────────────────────────────────
echo ""
echo "==> Manual steps remaining:"
echo "  tailscale up"
echo "  nordvpn login"
echo "  docker login gitlab.yourcompany.com"
echo ""
echo "Done."
