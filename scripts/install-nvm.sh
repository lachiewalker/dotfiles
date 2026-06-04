#!/usr/bin/env bash
set -euo pipefail

NVM_VERSION="v0.40.4"  # update when bumping

if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "  [skip] nvm already installed"
else
    echo "  [install] nvm ${NVM_VERSION}"
    # PROFILE=/dev/null prevents the installer from writing init lines to .bashrc
    # Init is managed by chezmoi via dot_bashrc.d/nvm.sh
    PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"

NODE_VERSION="22.14.0"
if nvm ls "$NODE_VERSION" &>/dev/null; then
    echo "  [skip] node ${NODE_VERSION} already installed"
else
    echo "  [install] node ${NODE_VERSION}"
    nvm install "$NODE_VERSION"
fi

nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
echo "  [done] node $(node --version)"
