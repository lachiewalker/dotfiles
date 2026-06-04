#!/usr/bin/env bash
set -euo pipefail

if command -v croc &>/dev/null; then
    echo "  [skip] croc already installed ($(croc --version 2>/dev/null || true))"
    exit 0
fi

echo "  [install] croc"
curl --proto '=https' --tlsv1.2 -fsSL https://getcroc.schollz.com | bash
echo "  [done] croc"
