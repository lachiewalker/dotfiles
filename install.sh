#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/lachiewalker/dotfiles.git"
NVM_VERSION="v0.40.4"
NODE_VERSION="22.14.0"

# bw CLI is a Node app that fails on IPv6 — force IPv4 for this entire script.
# ~/.bashrc sets this normally, but isn't sourced until after chezmoi apply.
export NODE_OPTIONS="--dns-result-order=ipv4first --no-network-family-autoselection"

# 1. git
if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    sudo apt-get update -qq
    sudo apt-get install -y git
fi

# 2. chezmoi
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# 3. nvm + node (needed before bw CLI)
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "==> Installing nvm ${NVM_VERSION}..."
    PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    echo "==> Installing node ${NODE_VERSION}..."
    nvm install "$NODE_VERSION"
fi
nvm use "$NODE_VERSION"

# 4. Bitwarden CLI
if ! command -v bw &>/dev/null; then
    echo "==> Installing Bitwarden CLI..."
    npm install -g @bitwarden/cli
fi

# 5. Bitwarden login + unlock
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

# 6. age (needed to decrypt work files before chezmoi apply)
if ! command -v age &>/dev/null; then
    echo "==> Installing age..."
    sudo apt-get install -y age
fi

# 7. age key — must exist before chezmoi apply can decrypt encrypted files
if [ ! -f "$HOME/.age/key.txt" ]; then
    echo ""
    echo "  IMPORTANT: age private key not found at ~/.age/key.txt"
    echo "  Retrieve it from Bitwarden before continuing."
    echo "  Once placed, re-run this script."
    exit 1
fi

# 8. Apply dotfiles
echo "==> Applying dotfiles..."
chezmoi init --apply "$REPO"

echo ""
echo "Dotfiles applied. Run scripts/install-packages.sh to install packages."
