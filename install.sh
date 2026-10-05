#!/usr/bin/env bash
set -euo pipefail

INSTALL_URL="https://raw.githubusercontent.com/lachiewalker/dotfiles/main/install.sh"

# `curl ... | bash` feeds this script on stdin, so every prompt (read, bw, gh, glab)
# would read script text instead of the keyboard. Re-run from a temp file with the
# terminal as stdin.
if [ ! -t 0 ] && [ -z "${DOTFILES_INSTALL_REEXEC:-}" ]; then
    self=$(mktemp --suffix=-install.sh)
    curl -fsSL "$INSTALL_URL" -o "$self"
    DOTFILES_INSTALL_REEXEC=1 exec bash "$self" "$@" </dev/tty
fi

REPO="https://github.com/lachiewalker/dotfiles.git"
NVM_VERSION="v0.40.4"
NODE_VERSION="22.14.0"
DOTFILES="$HOME/Projects/repos/dotfiles"

# bw CLI is a Node app that fails on IPv6 — force IPv4 for this entire script.
# ~/.bashrc sets this normally, but isn't sourced until after chezmoi apply.
export NODE_OPTIONS="--dns-result-order=ipv4first --no-network-family-autoselection"

# ── 0. Profile ─────────────────────────────────────────────────────────────────
if [[ -n "${CHEZMOI_PROFILE:-}" ]]; then
    echo "Using profile: ${CHEZMOI_PROFILE}"
else
    while true; do
        read -rp "Profile (desktop/server): " CHEZMOI_PROFILE </dev/tty
        case "$CHEZMOI_PROFILE" in
            desktop|server) break ;;
            *) echo "  Must be 'desktop' or 'server'." ;;
        esac
    done
fi
export CHEZMOI_PROFILE

# ── 1. git ─────────────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    sudo apt-get update -qq
    sudo apt-get install -y git
fi

# ── 2. chezmoi ─────────────────────────────────────────────────────────────────
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# ── 3. nvm + node (needed before bw CLI) ──────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "==> Installing nvm ${NVM_VERSION}..."
    PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    echo "==> Installing node ${NODE_VERSION}..."
    nvm install "$NODE_VERSION"
fi
nvm use "$NODE_VERSION"

# ── 4. Bitwarden CLI ───────────────────────────────────────────────────────────
if ! command -v bw &>/dev/null; then
    echo "==> Installing Bitwarden CLI..."
    npm install -g @bitwarden/cli
fi

# ── 5. Bitwarden login + unlock ────────────────────────────────────────────────
BW_STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unauthenticated")
if [ "$BW_STATUS" = "unauthenticated" ]; then
    echo "==> Log in to Bitwarden:"
    bw login
fi
if [ -z "${BW_SESSION:-}" ]; then
    echo "==> Unlock Bitwarden vault:"
    BW_SESSION=$(bw unlock --raw)
    export BW_SESSION
fi

# ── 6. age ─────────────────────────────────────────────────────────────────────
if ! command -v age &>/dev/null; then
    echo "==> Installing age..."
    sudo apt-get install -y age
fi

# ── 7. age key from Bitwarden ──────────────────────────────────────────────────
if [ ! -f "$HOME/.age/key.txt" ]; then
    echo "==> Retrieving age key from Bitwarden (chezmoi/age-key)..."
    mkdir -p "$HOME/.age"
    chmod 700 "$HOME/.age"
    bw get notes "chezmoi/age-key" > "$HOME/.age/key.txt"
    chmod 600 "$HOME/.age/key.txt"
fi

# ── 8. Apply dotfiles ──────────────────────────────────────────────────────────
echo "==> Applying dotfiles..."
# --source keeps the repo at $DOTFILES (default is ~/.local/share/chezmoi).
# --promptString is keyed by the prompt text in .chezmoi.toml.tmpl, not the data key.
chezmoi init --apply --source "$DOTFILES" \
    --promptString "Profile (desktop/server)=${CHEZMOI_PROFILE}" "$REPO"

# shellcheck source=scripts/lib/pause.sh
. "$DOTFILES/scripts/lib/pause.sh"

# ── 9. NVIDIA driver (only if an NVIDIA GPU is present) ───────────────────────
if lspci 2>/dev/null | grep -qi nvidia && ! command -v nvidia-smi &>/dev/null; then
    echo "==> Installing NVIDIA driver (ubuntu-drivers)..."
    sudo ubuntu-drivers install
fi

# ── 10. packages (apt repos, apt, .deb, runtimes, CLI tools, snap, flatpak, …) ─
echo "==> Installing packages..."
bash "$DOTFILES/scripts/install-packages.sh"

# ── 11. Docker without sudo ───────────────────────────────────────────────────
# The Docker socket belongs to root:docker. Without this group, every docker
# command needs sudo. Takes effect at next login.
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "==> Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
fi

# ── 12. SSH keys ───────────────────────────────────────────────────────────────
echo "==> Generating SSH keys..."
bash "$DOTFILES/scripts/setup-ssh.sh"

# ── 13. Auth (gh, glab, SSH key registration, Mullvad, Tailscale, Coder) ──────
echo "==> Setting up auth..."
bash "$DOTFILES/scripts/setup-auth.sh"

# ── 14. Docker registry login (work GitLab) ───────────────────────────────────
WORK_GITLAB="$(chezmoi execute-template '{{ .workGitlab }}' 2>/dev/null || true)"
if [[ -n "$WORK_GITLAB" ]]; then
    REGISTRY="${WORK_GITLAB}:5050"
    echo "==> Docker login to ${REGISTRY} (use a GitLab personal access token as the password)"
    # sg: run with the new docker group before the next login applies it
    if ! sg docker -c "docker login ${REGISTRY}"; then
        pause_for_user "Log in to the Docker registry" \
            "Automatic login failed. Run this in another terminal:" \
            "sg docker -c 'docker login ${REGISTRY}'"
    fi
fi

# ── 15. 2pi VPN (desktop) ──────────────────────────────────────────────────────
if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    echo "==> Importing 2pi VPN profile..."
    bash "$DOTFILES/scripts/setup-vpn-import.sh"
    echo "==> Setting up VPN split-tunnel..."
    bash "$DOTFILES/scripts/setup-vpn-split-tunnel.sh"
fi

# ── 16. Restore Firefox session from backup (desktop) ─────────────────────────
if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    echo "==> Restoring Firefox session from backup..."
    bash "$DOTFILES/scripts/restore-from-backup.sh"
fi

# ── 17. GNOME settings, terminal profiles, filmholes icon ─────────────────────
if [[ "${CHEZMOI_PROFILE:-desktop}" == "desktop" ]]; then
    echo "==> Restoring GNOME settings..."
    bash "$DOTFILES/gnome/restore.sh"
fi

# ── 18. NVIDIA Docker runtime (skip if no GPU) ────────────────────────────────
if command -v nvidia-smi &>/dev/null; then
    echo "==> Configuring NVIDIA Docker runtime..."
    bash "$DOTFILES/scripts/setup-nvidia-docker.sh"
fi

# ── 19. Finish ─────────────────────────────────────────────────────────────────
pause_for_user "Reboot" \
    "Reboot to apply the docker group, PATH changes in ~/.profile and the NVIDIA driver." \
    "After the reboot: connect the 2pi VPN once and enter its password when asked." \
    "Open Firefox: your windows and tabs come back from the backup."
echo "Done."
