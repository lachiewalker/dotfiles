#!/usr/bin/env bash
# One-time script: creates all chezmoi-related items in Bitwarden vault.
# Run manually: bash setup-bitwarden.sh
# After running, open Bitwarden → Chezmoi folder and replace all REPLACE_* values.
set -euo pipefail

if ! command -v bw >/dev/null 2>&1; then
    echo "Error: bw not found. Install with: npm install -g @bitwarden/cli" >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found. Install with: sudo apt install jq" >&2
    exit 1
fi

echo "Unlocking Bitwarden vault..."
BW_SESSION="$(bw unlock --raw)"
export BW_SESSION

# ── Create Chezmoi folder ──────────────────────────────────────────────────────
FOLDER_ID="$(
  bw get template folder \
  | jq '.name = "Chezmoi"' \
  | bw encode \
  | bw create folder \
  | jq -r '.id'
)"
echo "Created folder: Chezmoi ($FOLDER_ID)"

# ── chezmoi/git ────────────────────────────────────────────────────────────────
bw get template item | jq --arg fid "$FOLDER_ID" '
  .type = 1 | .name = "chezmoi/git" | .folderId = $fid |
  .fields = [
    {"name": "name",  "value": "REPLACE_FULL_NAME", "type": 0},
    {"name": "email", "value": "REPLACE_EMAIL",     "type": 0}
  ]
' | bw encode | bw create item >/dev/null
echo "Created: chezmoi/git"

# ── chezmoi/github ─────────────────────────────────────────────────────────────
bw get template item | jq --arg fid "$FOLDER_ID" '
  .type = 1 | .name = "chezmoi/github" | .folderId = $fid |
  .login.username = "REPLACE_GITHUB_USERNAME" |
  .login.password = "REPLACE_GITHUB_PAT"
' | bw encode | bw create item >/dev/null
echo "Created: chezmoi/github"


bw sync >/dev/null

echo ""
echo "Done. Items in Chezmoi folder:"
bw list items --folderid "$FOLDER_ID" | jq -r '.[].name'
echo ""
echo "Next: open Bitwarden → Chezmoi folder and replace all REPLACE_* values."
echo "Then run: chezmoi apply"
