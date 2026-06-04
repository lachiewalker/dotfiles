#!/usr/bin/env bash
# Copy wallpapers and profile pictures to ~/Pictures.
# Safe to re-run — copies without deleting existing files.
set -euo pipefail

DIR="$(dirname "$0")"

mkdir -p ~/Pictures/wallpaper ~/Pictures/profile

cp -n "$DIR"/wallpaper/* ~/Pictures/wallpaper/
cp -n "$DIR"/profile/*   ~/Pictures/profile/

echo "Pictures restored to ~/Pictures/wallpaper/ and ~/Pictures/profile/"
