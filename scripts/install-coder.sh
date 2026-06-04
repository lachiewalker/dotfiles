#!/usr/bin/env bash
set -euo pipefail

if command -v coder &>/dev/null; then
    echo "  [skip] coder already installed ($(coder version 2>/dev/null | head -1))"
    exit 0
fi

echo "  [install] coder"
curl --proto '=https' --tlsv1.2 -fsSL https://coder.com/install.sh | sh
echo "  [done] coder"
