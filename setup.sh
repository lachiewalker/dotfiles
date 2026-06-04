#!/usr/bin/env bash
# New machine bootstrap. Run after `chezmoi apply`.
# Safe to re-run — each step checks if already complete.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES_DIR/scripts"
PACKAGES="$DOTFILES_DIR/packages"

# ── Helpers ───────────────────────────────────────────────────────────────────
step() { echo ""; echo "══════════════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════════════"; }
ok()   { echo "  ✓ $1"; }
skip() { echo "  – $1 (already done)"; }

# ── 1. Dotfiles ───────────────────────────────────────────────────────────────
step "1/7  Dotfiles (chezmoi apply)"
if ! command -v chezmoi &>/dev/null; then
    echo "  Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
chezmoi apply
ok "Dotfiles applied"

# ── 2. SSH keys ───────────────────────────────────────────────────────────────
step "2/7  SSH keys"
bash "$SCRIPTS/setup-ssh.sh"

# ── 3. apt packages ───────────────────────────────────────────────────────────
step "3/7  apt packages"
if [[ -f "$PACKAGES/apt-install.sh" ]]; then
    sudo apt-get update -qq
    bash "$PACKAGES/apt-install.sh"
    ok "apt packages installed"
else
    echo "  ! packages/apt-install.sh not found — skipping (Phase 3 not yet complete)"
fi

# ── 4. Snap packages ──────────────────────────────────────────────────────────
step "4/7  Snap packages"
if [[ -f "$PACKAGES/snap-install.sh" ]]; then
    bash "$PACKAGES/snap-install.sh"
    ok "Snap packages installed"
else
    echo "  ! packages/snap-install.sh not found — skipping"
fi

# ── 5. Flatpak + pipx + npm globals ──────────────────────────────────────────
step "5/7  Flatpak / pipx / npm globals"
if [[ -f "$PACKAGES/flatpak-install.sh" ]]; then
    bash "$PACKAGES/flatpak-install.sh"
    ok "Flatpak apps installed"
else
    echo "  ! packages/flatpak-install.sh not found — skipping"
fi
if [[ -f "$PACKAGES/pipx-install.sh" ]]; then
    bash "$PACKAGES/pipx-install.sh"
    ok "pipx tools installed"
else
    echo "  ! packages/pipx-install.sh not found — skipping"
fi
if [[ -f "$PACKAGES/npm-install.sh" ]]; then
    bash "$PACKAGES/npm-install.sh"
    ok "npm globals installed"
else
    echo "  ! packages/npm-install.sh not found — skipping"
fi

# ── 6. Runtimes ───────────────────────────────────────────────────────────────
step "6/7  Runtimes (NVM, Rust, uv)"
if [[ -f "$SCRIPTS/install-nvm.sh" ]]; then
    bash "$SCRIPTS/install-nvm.sh"
    ok "NVM installed"
else
    echo "  ! scripts/install-nvm.sh not found — skipping (Phase 4 not yet complete)"
fi
if [[ -f "$SCRIPTS/install-rust.sh" ]]; then
    bash "$SCRIPTS/install-rust.sh"
    ok "Rust installed"
else
    echo "  ! scripts/install-rust.sh not found — skipping"
fi
if [[ -f "$SCRIPTS/install-uv.sh" ]]; then
    bash "$SCRIPTS/install-uv.sh"
    ok "uv installed"
else
    echo "  ! scripts/install-uv.sh not found — skipping"
fi

# ── 7. Auth (interactive) ────────────────────────────────────────────────────
step "7/7  Auth setup (gh, glab, NordVPN, Tailscale)"
echo "  This step is interactive — follow the prompts."
echo ""
bash "$SCRIPTS/setup-auth.sh"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  All done!"
echo "══════════════════════════════════════════"
echo ""
echo "Remaining manual steps:"
echo "  - Create ~/.gitconfig.local with work email + GitLab url.insteadOf"
echo "  - Create ~/.bashrc.local for any machine-specific overrides"
echo "  - aws sso login --profile <profile>  (when you need AWS access)"
echo "  - gpg --import  (if you use GPG signing)"
echo ""
echo "See README.md for full details."
