#!/usr/bin/env bash
set -euo pipefail

rm -f "$HOME/.config/quickshell/workspace-wallpapers/shell.qml"
rmdir "$HOME/.config/quickshell/workspace-wallpapers" 2>/dev/null || true

rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper"
rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper-config"
rm -f "$HOME/.local/share/applications/workspace-wallpapers.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

echo "Workspace Wallpapers files removed."
echo "Your ~/.config/caelestia/workspace-wallpapers.json was left untouched."
