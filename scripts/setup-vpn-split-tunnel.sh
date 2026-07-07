#!/usr/bin/env bash
# Split-tunnel the 2pi OpenVPN connection: only 2pisoftware.com internal hosts
# route through it, everything else stays on the normal connection.
#
# Requires the "2piLachlan" OpenVPN connection to already be imported into
# NetworkManager (manual step — the .ovpn file contains a private key/cert
# and isn't tracked here). Safe to re-run; skips cleanly if nmcli or the
# connection isn't present yet (e.g. server profile, or VPN not set up yet).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONNECTION_ID="2piLachlan"
DISPATCHER_SRC="$SCRIPT_DIR/networkmanager/90-2pisoftware-vpn-slice"
DISPATCHER_DEST="/etc/NetworkManager/dispatcher.d/90-2pisoftware-vpn-slice"

if ! command -v nmcli &>/dev/null; then
    echo "  – nmcli not found — skipping VPN split-tunnel setup"
    exit 0
fi

if ! nmcli -t -f NAME connection show | grep -qx "$VPN_CONNECTION_ID"; then
    echo "  – NetworkManager connection '$VPN_CONNECTION_ID' not found — skipping"
    echo "    (import the .ovpn file first, then re-run this script)"
    exit 0
fi

echo "  Installing NetworkManager dispatcher script..."
sed "s|__VPN_SLICE_BIN__|$HOME/.local/bin/vpn-slice|" "$DISPATCHER_SRC" \
    | sudo tee "$DISPATCHER_DEST" >/dev/null
sudo chown root:root "$DISPATCHER_DEST"
sudo chmod 755 "$DISPATCHER_DEST"

echo "  Setting ipv4.never-default on '$VPN_CONNECTION_ID' (stops it grabbing the default route)..."
nmcli connection modify "$VPN_CONNECTION_ID" ipv4.never-default yes

echo "  Done. Reconnect the VPN for the dispatcher script to take effect."
