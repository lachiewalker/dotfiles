#!/usr/bin/env bash
set -euo pipefail

# fd-find installs as 'fdfind' on Ubuntu — symlink to 'fd' for standard usage
if [ -L "$HOME/.local/bin/fd" ]; then
    echo "  [skip] fd symlink already exists"
else
    echo "  [link] fd -> fdfind"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi
