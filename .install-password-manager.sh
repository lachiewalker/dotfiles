#!/usr/bin/env bash
# chezmoi hook: [hooks.read-source-state.pre]
# Ensures bw CLI is installed before chezmoi attempts template rendering.
set -euo pipefail

OS="$(uname -s)"

install_bw_linux() {
    npm install -g @bitwarden/cli
}

install_bw_darwin() {
    brew install --quiet bitwarden-cli
}

if ! command -v bw >/dev/null 2>&1; then
    echo "chezmoi hook: bw not found, installing..."
    case "$OS" in
        Linux)  install_bw_linux ;;
        Darwin) install_bw_darwin ;;
        *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
    esac
    echo "chezmoi hook: bw installed ($(bw --version))"
fi
