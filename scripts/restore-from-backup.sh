#!/usr/bin/env bash
set -euo pipefail

# Restore the Firefox session (open windows and tabs) from the rustic backup.
# Safe to re-run. Needs AWS session tokens and the rustic password.
# Before wiping the old machine: close Firefox, then run `rustic backup`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/pause.sh
. "$SCRIPT_DIR/lib/pause.sh"
# shellcheck source=/dev/null
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

FIREFOX_DIR="$HOME/.mozilla/firefox"

if ! command -v rustic &>/dev/null; then
    echo "  [skip] rustic not installed — run this script again after cargo-install.sh"
    exit 0
fi

# ── AWS session tokens ────────────────────────────────────────────────────────
pause_for_user "Get AWS session tokens" \
    "1. Open Firefox, sign in to Firefox Sync and unlock Bitwarden." \
    "2. In the AWS access portal, copy the 'export AWS_...' lines." \
    "3. Press Enter here, then paste the lines at the next prompt."

echo "  Paste the export lines (hidden). Reading stops when all three keys arrive:"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
# Echo off for the whole paste: read -s hides only the line being read, and a
# multi-line paste arrives at once, so later lines would show on screen
stty -echo </dev/tty
trap 'stty echo </dev/tty' EXIT
# Parse the export lines instead of eval-ing pasted text
while IFS= read -r line </dev/tty; do
    line="${line%$'\r'}"
    if [[ $line =~ ^[[:space:]]*export[[:space:]]+(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)=\"?([^\"]*)\"?[[:space:]]*$ ]]; then
        export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        echo "  [ok] ${BASH_REMATCH[1]}"
    fi
    if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] && [ -n "${AWS_SESSION_TOKEN:-}" ]; then
        break
    fi
done
stty echo </dev/tty

read -rsp "  rustic repository password: " RUSTIC_PASSWORD </dev/tty
echo ""
export RUSTIC_PASSWORD
export RUSTIC_NO_PROGRESS=true
if ! rustic snapshots &>/dev/null; then
    echo "  [skip] cannot open the rustic repository — run scripts/restore-from-backup.sh later"
    exit 0
fi

# ── Firefox session ───────────────────────────────────────────────────────────
echo "==> Restoring Firefox session..."
# The Mozilla build runs as firefox-bin, the snap as firefox
while pgrep -x 'firefox|firefox-bin' &>/dev/null; do
    pause_for_user "Close Firefox" \
        "Firefox overwrites its session file when it closes." \
        "Close every Firefox window."
done

profile=$(awk -F= '$1 == "Default" { print $2; exit }' "$FIREFOX_DIR/installs.ini" 2>/dev/null || true)
if [ -z "$profile" ] || [ ! -d "$FIREFOX_DIR/$profile" ]; then
    echo "  [skip] no Firefox profile — open Firefox once, then run this script again"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"; stty echo </dev/tty' EXIT
if ! rustic restore --filter-paths "$FIREFOX_DIR" "latest:$FIREFOX_DIR" "$tmp"; then
    echo "  [warn] no Firefox snapshot found"
    exit 0
fi

# Newest of the clean-exit file and the running-session file (rustic keeps mtimes)
session=$(find "$tmp" -type f \( -name sessionstore.jsonlz4 -o -name recovery.jsonlz4 \) -printf '%T@ %p\n' \
    | sort -n | tail -1 | cut -d' ' -f2-)
if [ -z "$session" ]; then
    echo "  [warn] Firefox snapshot has no session file"
    exit 0
fi

cp "$session" "$FIREFOX_DIR/$profile/sessionstore.jsonlz4"
rm -f "$FIREFOX_DIR/$profile"/sessionstore-backups/recovery.*
# "Open previous windows and tabs" — a normal pref, so you can change it later in Settings
echo 'user_pref("browser.startup.page", 3);' >> "$FIREFOX_DIR/$profile/prefs.js"
echo "  [done] Firefox restores your windows and tabs on next start"
