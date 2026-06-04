#!/usr/bin/env bash
set -euo pipefail

if command -v uv &>/dev/null; then
    echo "  [skip] uv already installed ($(uv --version))"
else
    echo "  [install] uv"
    curl --proto '=https' --tlsv1.2 -fsSL https://astral.sh/uv/install.sh | sh
    echo "  [done] $(uv --version)"
fi
