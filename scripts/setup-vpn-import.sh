#!/usr/bin/env bash
set -euo pipefail

# Import the 2pi OpenVPN profile into NetworkManager from Bitwarden.
# Bitwarden item "chezmoi/2pi-vpn" (Login type):
#   - attachment: 2piLachlan.ovpn  (embeds the cert/key, so it never goes in this repo)
#   - username:   VPN username
#   - password:   VPN password (NetworkManager asks for it on first connect)
# Falls back to a guided manual import if Bitwarden has no copy.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/pause.sh
. "$SCRIPT_DIR/lib/pause.sh"

VPN_NAME="2piLachlan"
BW_ITEM="chezmoi/2pi-vpn"

if ! command -v nmcli &>/dev/null; then
    echo "  – nmcli not found — skipping VPN import"
    exit 0
fi

if nmcli -t -f NAME connection show | grep -qx "$VPN_NAME"; then
    echo "  [skip] ${VPN_NAME} already imported"
    exit 0
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
ovpn="$tmpdir/${VPN_NAME}.ovpn"

item_id=$(bw get item "$BW_ITEM" 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' 2>/dev/null || true)

if [ -n "$item_id" ] && bw get attachment "${VPN_NAME}.ovpn" --itemid "$item_id" --output "$ovpn" &>/dev/null; then
    echo "  [import] ${VPN_NAME} from Bitwarden"
    # Connection name comes from the file name, so it is "2piLachlan"
    nmcli connection import type openvpn file "$ovpn"
    username=$(bw get username "$BW_ITEM" 2>/dev/null || true)
    if [ -n "$username" ]; then
        nmcli connection modify "$VPN_NAME" +vpn.data "username=${username}"
    fi
    echo "  [done] NetworkManager asks for the VPN password on first connect"
else
    pause_for_user "Import the 2pi VPN profile" \
        "Bitwarden item '${BW_ITEM}' with attachment '${VPN_NAME}.ovpn' not found." \
        "1. Settings → Network → VPN → + → Import from file… → choose ${VPN_NAME}.ovpn" \
        "2. Make sure the connection name is exactly '${VPN_NAME}'"
fi
