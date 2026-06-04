# NVM init — chezmoi manages this file; install scripts use PROFILE=/dev/null to prevent NVM from overwriting it
# shellcheck shell=bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
