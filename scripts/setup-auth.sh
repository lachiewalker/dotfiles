#!/usr/bin/env bash
# Interactive auth setup for a new machine.
# Run AFTER setup-ssh.sh. Steps that are already complete are skipped automatically.
set -euo pipefail

# ── GitHub ────────────────────────────────────────────────────────────────────
echo "==> GitHub (gh auth login)"
if gh auth status &>/dev/null; then
    echo "  Already authenticated, skipping"
else
    gh auth login
fi

echo ""
echo "==> Registering SSH key with GitHub"
if gh ssh-key list | grep -q "$(awk '{print $2}' ~/.ssh/github.pub)"; then
    echo "  Key already registered, skipping"
else
    gh ssh-key add ~/.ssh/github.pub --title "$(hostname -s)"
    echo "  Key added: $(hostname -s)"
fi

echo ""
echo "==> Testing GitHub SSH"
ssh -T -i ~/.ssh/github git@github.com 2>&1 || true

# ── GitLab ────────────────────────────────────────────────────────────────────
echo ""
echo "==> GitLab (glab auth login)"
if glab auth status &>/dev/null; then
    echo "  Already authenticated, skipping"
else
    glab auth login
fi

echo ""
echo "==> Testing GitLab SSH (internal)"
WORK_GITLAB="$(chezmoi data 2>/dev/null | grep -oP '(?<="workGitlab":")[^"]+' || true)"
if [[ -n "$WORK_GITLAB" ]]; then
    ssh -T -i ~/.ssh/gitlab "git@$WORK_GITLAB" 2>&1 || true
else
    echo "  workGitlab not configured in chezmoi, skipping"
fi

# ── NordVPN ───────────────────────────────────────────────────────────────────
echo ""
echo "==> NordVPN login"
if nordvpn account &>/dev/null; then
    echo "  Already logged in, skipping"
else
    nordvpn login
fi

# ── Tailscale ─────────────────────────────────────────────────────────────────
echo ""
echo "==> Tailscale"
if tailscale status &>/dev/null; then
    echo "  Already connected, skipping"
else
    sudo tailscale up
fi

# ── Coder ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Coder SSH config"
if command -v coder &>/dev/null; then
    coder config-ssh
else
    echo "  coder not installed, skipping"
fi

echo ""
echo "==> All done. Manual steps remaining:"
echo "  - glab auth login --hostname <work-gitlab-hostname> (if internal GitLab needs separate auth)"
echo "  - aws sso login --profile <profile> (when you need AWS access)"
echo "  - gpg --import (if you need GPG signing)"
