#!/usr/bin/env bash
set -euo pipefail

GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1 | sed 's/^go//')

INSTALLED=$(/usr/local/go/bin/go version 2>/dev/null | grep -oP 'go\K[0-9.]+' || true)
if [ "$INSTALLED" = "$GO_VERSION" ]; then
    echo "  [skip] go ${GO_VERSION} already installed"
    exit 0
fi

echo "  [install] go ${GO_VERSION}"
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
echo "  [done] $(/usr/local/go/bin/go version)"
