#!/usr/bin/env bash
# Interactive auth setup for a new machine.
# Run AFTER setup-ssh.sh. Steps that are already complete are skipped automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/pause.sh
. "$SCRIPT_DIR/lib/pause.sh"

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

# ── GitLab (work) ─────────────────────────────────────────────────────────────
WORK_GITLAB="$(chezmoi execute-template '{{ .workGitlab }}' 2>/dev/null || true)"
if [[ -n "$WORK_GITLAB" ]]; then
    echo ""
    echo "==> GitLab (glab auth login --hostname $WORK_GITLAB)"
    if glab auth status --hostname "$WORK_GITLAB" &>/dev/null; then
        echo "  Already authenticated, skipping"
    else
        glab auth login --hostname "$WORK_GITLAB"
    fi

    echo ""
    echo "==> Registering SSH key with GitLab"
    if GITLAB_HOST="$WORK_GITLAB" glab ssh-key list 2>/dev/null | grep -q "$(awk '{print $2}' ~/.ssh/gitlab.pub)"; then
        echo "  Key already registered, skipping"
    elif GITLAB_HOST="$WORK_GITLAB" glab ssh-key add ~/.ssh/gitlab.pub --title "$(hostname -s)"; then
        echo "  Key added: $(hostname -s)"
    else
        pause_for_user "Add the GitLab SSH key" \
            "glab could not add the key automatically." \
            "1. Copy this key: $(cat ~/.ssh/gitlab.pub)" \
            "2. Paste it at https://${WORK_GITLAB}/-/user_settings/ssh_keys"
    fi

    echo ""
    echo "==> Testing GitLab SSH (internal)"
    ssh -T -i ~/.ssh/gitlab "git@$WORK_GITLAB" 2>&1 || true
else
    echo "  workGitlab not configured in chezmoi, skipping GitLab"
fi

# ── Mullvad ───────────────────────────────────────────────────────────────────
echo ""
echo "==> Mullvad login"
if ! command -v mullvad &>/dev/null; then
    echo "  mullvad not installed, skipping"
elif mullvad account get &>/dev/null; then
    echo "  Already logged in, skipping"
else
    read -rp "  Mullvad account number: " MULLVAD_ACCOUNT
    mullvad account login "$MULLVAD_ACCOUNT"
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
echo "  - aws sso login --profile <profile> (when you need AWS access)"
echo "  - gpg --import (if you need GPG signing)"
