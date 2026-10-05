#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
. "$HOME/.cargo/env"

# cargo-binstall fetches prebuilt binaries instead of compiling from source
if ! command -v cargo-binstall &>/dev/null; then
    echo "  [install] cargo-binstall"
    curl -L --proto '=https' --tlsv1.2 -sSf \
        https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
fi

DIR="$(dirname "$0")"
xargs cargo binstall -y < "$DIR/cargo.txt"
