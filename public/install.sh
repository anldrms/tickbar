#!/usr/bin/env bash
set -euo pipefail

DMG_URL="https://tickbar.vercel.app/downloads/TickBar-macOS-Universal.dmg"
TMP_DMG="/tmp/TickBar-macOS-Universal-$$.dmg"
MOUNT_POINT="/Volumes/TickBar"

echo "==> Downloading TickBar (macOS Universal)..."
curl -fL --progress-bar "$DMG_URL" -o "$TMP_DMG"

if [ -d "$MOUNT_POINT" ]; then
    hdiutil detach "$MOUNT_POINT" -quiet || true
fi

echo "==> Mounting disk image..."
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_POINT" "$TMP_DMG" -quiet

echo "==> Installing TickBar.app to /Applications..."
killall TickBar 2>/dev/null || true
rm -rf /Applications/TickBar.app
ditto --norsrc --noextattr "$MOUNT_POINT/TickBar.app" /Applications/TickBar.app
xattr -cr /Applications/TickBar.app

hdiutil detach "$MOUNT_POINT" -quiet || true
rm -f "$TMP_DMG"

echo "==> Launching TickBar..."
open -a /Applications/TickBar.app
echo "==> Done! TickBar is now running in your macOS menu bar."
