#!/usr/bin/env bash
set -euo pipefail

if command -v rustc &>/dev/null; then
    echo "  [skip] rust already installed ($(rustc --version))"
else
    echo "  [install] rust via rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# shellcheck source=/dev/null
. "$HOME/.cargo/env"
echo "  [done] $(rustc --version)"
