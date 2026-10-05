#!/usr/bin/env bash
set -euo pipefail

if command -v claude &>/dev/null; then
    echo "  [skip] claude already installed ($(claude --version))"
    exit 0
fi

echo "  [install] claude (native)"
curl -fsSL https://claude.ai/install.sh | bash
