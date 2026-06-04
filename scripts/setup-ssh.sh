#!/usr/bin/env bash
# Generate named SSH keys for github and gitlab.
# Safe to re-run — skips any key that already exists.
set -euo pipefail

if [[ -z "${1:-}" ]]; then
    read -rp "SSH key email: " EMAIL
else
    EMAIL="$1"
fi

generate_key() {
    local name="$1"
    local keyfile="$HOME/.ssh/$name"

    if [[ -f "$keyfile" ]]; then
        echo "  $keyfile already exists, skipping"
        return
    fi

    ssh-keygen -t ed25519 -C "$EMAIL" -f "$keyfile" -N ""
    echo "  Generated $keyfile"
}

echo "==> Generating SSH keys (email: $EMAIL)"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
generate_key github
generate_key gitlab

echo ""
echo "==> Adding keys to ssh-agent"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github ~/.ssh/gitlab

echo ""
echo "==> Public keys (add these to GitHub/GitLab if not using setup-auth.sh):"
echo ""
echo "  github.pub:  $(cat ~/.ssh/github.pub)"
echo "  gitlab.pub:  $(cat ~/.ssh/gitlab.pub)"
echo ""
echo "Next: run scripts/setup-auth.sh to log in to gh, glab, and register the GitHub key automatically."
