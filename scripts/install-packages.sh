#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_DIR="$SCRIPTS_DIR/../packages"

echo "==> Setting up apt repositories..."
bash "$SCRIPTS_DIR/setup-repos.sh"

echo "==> Installing apt packages..."
bash "$PACKAGES_DIR/apt-install.sh"

echo "==> Installing .deb apps..."
bash "$SCRIPTS_DIR/install-deb-apps.sh"

echo "==> Installing runtimes..."
bash "$SCRIPTS_DIR/install-nvm.sh"
bash "$SCRIPTS_DIR/install-rust.sh"
bash "$SCRIPTS_DIR/install-go.sh"
bash "$SCRIPTS_DIR/install-uv.sh"

echo "==> Installing CLI tools..."
bash "$SCRIPTS_DIR/install-aws-cli.sh"
bash "$SCRIPTS_DIR/install-session-manager.sh"
bash "$SCRIPTS_DIR/install-coder.sh"
bash "$SCRIPTS_DIR/install-croc.sh"
bash "$SCRIPTS_DIR/install-ollama.sh"

echo "==> Setting up symlinks..."
bash "$SCRIPTS_DIR/setup-symlinks.sh"

echo "==> Installing snap packages..."
bash "$PACKAGES_DIR/snap-install.sh"

echo "==> Installing flatpak packages..."
bash "$PACKAGES_DIR/flatpak-install.sh"

echo "==> Installing pipx tools..."
bash "$PACKAGES_DIR/pipx-install.sh"

echo "==> Installing npm global packages..."
# Ensure nvm node is active
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
bash "$PACKAGES_DIR/npm-install.sh"

echo ""
echo "All packages installed."
