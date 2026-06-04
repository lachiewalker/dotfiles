#!/usr/bin/env bash
set -euo pipefail

if command -v session-manager-plugin &>/dev/null; then
    echo "  [skip] session-manager-plugin already installed"
    exit 0
fi

echo "  [install] aws session manager plugin"
curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o /tmp/smp.deb
sudo dpkg -i /tmp/smp.deb
rm /tmp/smp.deb
echo "  [done] session-manager-plugin"
