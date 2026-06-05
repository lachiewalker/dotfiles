#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew if absent
if ! command -v brew &>/dev/null; then
    echo "  [install] homebrew"
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for the rest of this script
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "  [done] brew $(brew --version | head -1)"

brew install rustic s5cmd
