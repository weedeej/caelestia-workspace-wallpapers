#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

QS_DIR="$HOME/.config/quickshell/workspace-wallpapers"
CAELESTIA_SCRIPTS="$HOME/.config/caelestia/scripts"
APP_DIR="$HOME/.local/share/applications"
CONFIG="$HOME/.config/caelestia/workspace-wallpapers.json"

missing=()

for command in qs caelestia jq python3 ffmpeg ffprobe hyprctl mpvpaper \
    flock setsid find; do
    command -v "$command" >/dev/null 2>&1 ||
        missing+=("$command")
done

if ((${#missing[@]} > 0)); then
    printf 'Missing required commands: %s\n' "${missing[*]}" >&2
    echo "Install/build the missing dependencies, then rerun ./install.sh." >&2
    exit 1
fi

mkdir -p \
    "$QS_DIR" \
    "$QS_DIR/app" \
    "$CAELESTIA_SCRIPTS" \
    "$APP_DIR" \
    "$HOME/Pictures/Wallpapers" \
    "$HOME/Videos/Wallpapers" \
    "$(dirname "$CONFIG")"

install -m 0644 \
    "$ROOT/quickshell/shell.qml" \
    "$QS_DIR/shell.qml"

shopt -s nullglob
app_files=("$ROOT"/quickshell/app/*.qml "$ROOT"/quickshell/app/*.js)
shopt -u nullglob

if ((${#app_files[@]} == 0)); then
    echo "No Quickshell application files found." >&2
    exit 1
fi

# Keep the private application module identical to the installed version.
rm -f -- "$QS_DIR/app/"*.qml "$QS_DIR/app/"*.js

install -m 0644 \
    "${app_files[@]}" \
    "$QS_DIR/app/"

install -m 0755 \
    "$ROOT/scripts/workspace-wallpaper" \
    "$CAELESTIA_SCRIPTS/workspace-wallpaper"

install -m 0755 \
    "$ROOT/scripts/workspace-wallpaper-ipc" \
    "$CAELESTIA_SCRIPTS/workspace-wallpaper-ipc"

install -m 0755 \
    "$ROOT/scripts/workspace-wallpaper-media" \
    "$CAELESTIA_SCRIPTS/workspace-wallpaper-media"

install -m 0755 \
    "$ROOT/scripts/workspace-wallpaper-transfer" \
    "$CAELESTIA_SCRIPTS/workspace-wallpaper-transfer"

install -m 0644 \
    "$ROOT/scripts/workspace_wallpaper_transfer_lib.py" \
    "$CAELESTIA_SCRIPTS/workspace_wallpaper_transfer_lib.py"

# Remove the pre-consolidation config helper when upgrading.
rm -f "$CAELESTIA_SCRIPTS/workspace-wallpaper-config"

install -m 0644 \
    "$ROOT/desktop/workspace-wallpapers.desktop" \
    "$APP_DIR/workspace-wallpapers.desktop"

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
echo
echo "Image directory:  ~/Pictures/Wallpapers"
echo "Video directory:  ~/Videos/Wallpapers"
echo
echo "Next:"
echo "  1. Add examples/workspace-hook.lua to your Caelestia Lua config."
echo "  2. Run: qs -c workspace-wallpapers"
echo
echo "You can also launch Workspace Wallpapers from your app launcher."
