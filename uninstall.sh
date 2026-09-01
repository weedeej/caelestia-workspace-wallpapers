#!/usr/bin/env bash
set -euo pipefail

rm -f "$HOME/.config/quickshell/workspace-wallpapers/shell.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/WorkspaceWallpapers.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/WallpaperCard.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/WallpaperGrid.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/VideoFrameEditor.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/AppState.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/ConfigService.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/LinkButton.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/MainWindow.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/MediaErrorCollector.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/MediaService.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/PickerController.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/PickerHeader.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/PickerPanel.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/ThemeService.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/TransferMenuItem.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/TransferToolbar.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/WorkspaceCombo.qml"
rm -f "$HOME/.config/quickshell/workspace-wallpapers/app/WorkspaceOverview.qml"
rmdir "$HOME/.config/quickshell/workspace-wallpapers/app" 2>/dev/null || true
rmdir "$HOME/.config/quickshell/workspace-wallpapers" 2>/dev/null || true

rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper"
rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper-config"
rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper-ipc"
rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper-media"
rm -f "$HOME/.config/caelestia/scripts/workspace-wallpaper-transfer"
rm -f "$HOME/.config/caelestia/scripts/workspace_wallpaper_transfer_lib.py"

rm -f "$HOME/.local/share/applications/workspace-wallpapers.desktop"

rm -rf -- "$HOME/.cache/caelestia-workspace-wallpapers"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

echo "Workspace Wallpapers files removed."
echo "Generated video and thumbnail caches were removed."
echo "Configuration and original wallpaper media were left untouched."
