#!/usr/bin/env bash
set -euo pipefail

# Add all external apt repositories needed before running packages/apt-install.sh.
# Idempotent — skips repos already configured.

add_repo() {
    local name="$1" keyring="$2" key_url="$3" list_entry="$4"
    local list_file="/etc/apt/sources.list.d/${name}.list"
    if [ -f "$list_file" ]; then
        echo "  [skip] ${name} repo already configured"
        return
    fi
    echo "  [add]  ${name}"
    curl -fsSL "$key_url" | gpg --dearmor | sudo tee "/usr/share/keyrings/${keyring}" > /dev/null
    echo "$list_entry" | sudo tee "$list_file" > /dev/null
}

echo "==> Setting up external apt repositories..."

# VS Code
add_repo "vscode" "microsoft.gpg" \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"

# Docker
add_repo "docker" "docker.gpg" \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Firefox (Mozilla official — Ubuntu's apt version is a snap redirector)
add_repo "mozilla" "mozilla.gpg" \
    "https://packages.mozilla.org/apt/repo-signing-key.gpg" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main"

# Pin Firefox to Mozilla repo over Ubuntu's snap redirector
if [ ! -f /etc/apt/preferences.d/mozilla-firefox ]; then
    echo "  [add]  firefox pin"
    sudo tee /etc/apt/preferences.d/mozilla-firefox > /dev/null <<'EOF'
Package: firefox*
Pin: release o=packages.mozilla.org
Pin-Priority: 1001
EOF
fi

# GitHub CLI
add_repo "github-cli" "githubcli.gpg" \
    "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli.gpg] https://cli.github.com/packages stable main"

# Google Chrome
add_repo "google-chrome" "google-chrome.gpg" \
    "https://dl.google.com/linux/linux_signing_key.pub" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb stable main"

# Mattermost
add_repo "mattermost" "mattermost.gpg" \
    "https://deb.packages.mattermost.com/pubkey.gpg" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/mattermost.gpg] https://deb.packages.mattermost.com stable main"

# NVIDIA Container Toolkit
if [ ! -f /etc/apt/sources.list.d/nvidia-container-toolkit.list ]; then
    echo "  [add]  nvidia-container-toolkit"
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
else
    echo "  [skip] nvidia-container-toolkit repo already configured"
fi

# Signal (intentionally uses 'xenial' distro string — Signal's official method for all Ubuntu/Debian)
add_repo "signal" "signal.gpg" \
    "https://updates.signal.org/desktop/apt/keys.asc" \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/signal.gpg] https://updates.signal.org/desktop/apt xenial main"

# Tailscale
if [ ! -f /etc/apt/sources.list.d/tailscale.list ]; then
    echo "  [add]  tailscale"
    curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg" \
        | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
    curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list" \
        | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
else
    echo "  [skip] tailscale repo already configured"
fi

echo "==> Updating apt..."
sudo apt-get update

echo "==> Done. Run packages/apt-install.sh next."
