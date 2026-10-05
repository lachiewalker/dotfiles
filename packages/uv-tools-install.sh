#!/usr/bin/env bash
set -euo pipefail

# uv installs to ~/.local/bin, which may not be on PATH yet on a fresh machine
export PATH="$HOME/.local/bin:$PATH"

DIR="$(dirname "$0")"
xargs -n1 uv tool install < "$DIR/uv-tools.txt"
