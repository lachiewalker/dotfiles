#!/usr/bin/env bash
set -euo pipefail

if command -v ollama &>/dev/null; then
    echo "  [skip] ollama already installed ($(ollama --version))"
    exit 0
fi

echo "  [install] ollama"
curl --proto '=https' --tlsv1.2 -fsSL https://ollama.ai/install.sh | sh
echo "  [done] $(ollama --version)"
echo "  [note] pull models manually: ollama pull <model>"
