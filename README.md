# Caelestia Workspace Wallpapers

A Quickshell utility for assigning wallpapers per Hyprland workspace while preserving Caelestia's adaptive wallpaper and color workflow.

## Features

- Explicit default wallpaper
- Per-workspace wallpaper overrides
- Unconfigured workspaces inherit the default
- Random wallpaper mode per workspace
- Uses `caelestia wallpaper -f`
- Adaptive Caelestia colors
- Desktop launcher included

## Requirements

You need:

- Hyprland
- Caelestia Shell
- Quickshell
- `jq`
- `flock` (normally from `util-linux`)

On Arch/CachyOS:

```bash
sudo pacman -S jq
```

Wallpapers are read from:

```text
~/Pictures/Wallpapers
```

Supported picker formats: JPG, JPEG, PNG, WEBP.

## Install

```bash
chmod +x install.sh
./install.sh
```

This installs:

```text
quickshell/shell.qml
  -> ~/.config/quickshell/workspace-wallpapers/shell.qml

scripts/workspace-wallpaper
  -> ~/.config/caelestia/scripts/workspace-wallpaper

scripts/workspace-wallpaper-config
  -> ~/.config/caelestia/scripts/workspace-wallpaper-config

desktop/workspace-wallpapers.desktop
  -> ~/.local/share/applications/workspace-wallpapers.desktop
```

Your config lives at:

```text
~/.config/caelestia/workspace-wallpapers.json
```

Existing config is never overwritten.

## Workspace hook

Add the hook from `examples/workspace-hook.lua` to the Caelestia Lua config `~/.config/caelestia/hypr-user.lua` where `hl` is available. Create if not existing:

```lua
hl.on("workspace.active", function(workspace)
    hl.exec_cmd(
        os.getenv("HOME") ..
        "/.config/caelestia/scripts/workspace-wallpaper " ..
        tostring(workspace.id)
    )
end)
```

## Run

```bash
qs -c workspace-wallpapers
```

Or launch **Workspace Wallpapers** from your application launcher.

## Config format

```json
{
  "default": "/home/user/Pictures/Wallpapers/default.jpg",
  "workspaces": {
    "2": "/home/user/Pictures/Wallpapers/work.jpg",
    "4": "__CAELESTIA_RANDOM__"
  }
}
```

An absent workspace key means inherit the default.

`__CAELESTIA_RANDOM__` is an internal sentinel used by the backend. Slect Random from the UI rather than editing it manually.

## Random mode

When a workspace uses Random:

```text
workspace switch
→ workspace-wallpaper
→ choose image from ~/Pictures/Wallpapers
→ caelestia wallpaper -f /absolute/path
```

The selection is resolved every time the workspace is entered.

## Adaptive colors

The app watches Caelestia's generated `scheme.json`.

On a scheme change, the utility performs a short fade-swap so Qt controls do not visibly repaint in a mixture of the old and new light/dark schemes.

## Why the backend only calls `caelestia wallpaper`

Caelestia already handles its adaptive scheme when the wallpaper changes. The backend therefore does not separately call `caelestia scheme`, avoiding duplicate work and race conditions.

## Closing

Closing the final utility window, including through a Hyprland `SUPER+Q` bind, exits the standalone `qs -c workspace-wallpapers` process.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller deliberately leaves your wallpaper configuration file untouched.

## Scope

This is a local companion utility and is not an official Caelestia component.

No GTK/Thunar theme manipulation is included.
