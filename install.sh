#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

QS_DIR="$HOME/.config/quickshell/workspace-wallpapers"
CAELESTIA_SCRIPTS="$HOME/.config/caelestia/scripts"
APP_DIR="$HOME/.local/share/applications"
CONFIG="$HOME/.config/caelestia/workspace-wallpapers.json"

mkdir -p "$QS_DIR" "$CAELESTIA_SCRIPTS" "$APP_DIR" "$(dirname "$CONFIG")"

install -m 0644 "$ROOT/quickshell/shell.qml" "$QS_DIR/shell.qml"
install -m 0755 "$ROOT/scripts/workspace-wallpaper" "$CAELESTIA_SCRIPTS/workspace-wallpaper"
install -m 0755 "$ROOT/scripts/workspace-wallpaper-config" "$CAELESTIA_SCRIPTS/workspace-wallpaper-config"
install -m 0644 "$ROOT/desktop/workspace-wallpapers.desktop" "$APP_DIR/workspace-wallpapers.desktop"

if [[ ! -f "$CONFIG" ]]; then
    cat > "$CONFIG" <<EOF
{
  "default": "",
  "workspaces": {}
}
EOF
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

echo
echo "Workspace Wallpapers installed."
echo "Next:"
echo "  1. Add examples/workspace-hook.lua to your Caelestia Lua config."
echo "  2. Put wallpapers in ~/Pictures/Wallpapers."
echo "  3. Run: qs -c workspace-wallpapers"
echo
echo "You can also launch 'Workspace Wallpapers' from your app launcher."
