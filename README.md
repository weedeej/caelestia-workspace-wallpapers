# Caelestia Workspace Wallpapers

A Quickshell utility for assigning image and video wallpapers per Hyprland workspace while preserving Caelestia's adaptive wallpaper and color workflow.

## Features

- Explicit default wallpaper
- Per-workspace wallpaper overrides
- Unconfigured workspaces inherit the default
- Random wallpaper mode per workspace
- Video wallpaper support with `mpvpaper`
- Video reference-frame selection for Caelestia theming
- Draggable video timeline with generated frame thumbnails
- Configurable video thumbnail interval, defaulting to 5 seconds
- JSON config import and export
- Portable ZIP import and export with referenced media assets
- Uses `caelestia wallpaper -f`
- Adaptive Caelestia colors
- Desktop launcher included

## Requirements

You need:

- Hyprland
- Caelestia Shell
- Quickshell
- `jq`
- `ffmpeg`
- `ffprobe`
- `mpvpaper`
- Python 3
- `flock` and `setsid` (normally from `util-linux`)

On Arch/CachyOS:

```bash
sudo pacman -S jq ffmpeg
```

`mpvpaper` must also be installed and available in your `PATH`.

Image wallpapers are read from:

```text
~/Pictures/Wallpapers
```

Video wallpapers are read from:

```text
~/Videos/Wallpapers
```

Supported image picker formats: JPG, JPEG, PNG, WEBP.

Supported video picker formats: MP4, WEBM, MKV, MOV, M4V, AVI.

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

scripts/workspace-wallpaper-media
  -> ~/.config/caelestia/scripts/workspace-wallpaper-media

scripts/workspace-wallpaper-transfer
  -> ~/.config/caelestia/scripts/workspace-wallpaper-transfer

desktop/workspace-wallpapers.desktop
  -> ~/.local/share/applications/workspace-wallpapers.desktop
```

Your config lives at:

```text
~/.config/caelestia/workspace-wallpapers.json
```

Existing config is never overwritten.

The installer also creates these directories if they do not already exist:

```text
~/Pictures/Wallpapers
~/Videos/Wallpapers
```

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
    "3": {
      "type": "video",
      "path": "/home/user/Videos/Wallpapers/blackhole.webm",
      "themeFrame": 15.0,
      "interval": 5
    },
    "4": "__CAELESTIA_RANDOM__"
  }
}
```

An absent workspace key means inherit the default.

Image entries remain plain absolute file paths for backward compatibility.

Video entries use an object containing the video path, selected theme-reference timestamp, and thumbnail interval.

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

Random mode currently selects image wallpapers only.

## Video wallpapers

Clicking a video in the wallpaper picker opens a reference-frame editor.

The editor displays a draggable timeline spanning the duration of the video. The timeline background is built from frame thumbnails extracted from the video.

By default, a new thumbnail is generated every 5 seconds.

The interval can be changed in the UI to:

```text
1s
2s
5s
10s
15s
30s
```

The selected timeline position is stored as `themeFrame` and is used as the reference image for Caelestia's adaptive colors.

Example:

```json
{
  "type": "video",
  "path": "/home/user/Videos/Wallpapers/blackhole.webm",
  "themeFrame": 23.4,
  "interval": 5
}
```

`themeFrame` is measured in seconds.

## Video playback

Video wallpapers are played with `mpvpaper`.

The backend uses:

```text
loop-file=inf no-audio panscan=1.0
```

`panscan=1.0` gives wallpaper-style cover behavior. Videos are scaled to fill the display and excess width or height is cropped instead of leaving black bars.

## Video theming

When a video workspace is entered:

```text
workspace switch
→ stop the previous mpvpaper wallpaper on the output
→ extract the configured theme reference frame
→ caelestia wallpaper -f reference-frame.jpg
→ wait briefly for Caelestia's scheme to update
→ start mpvpaper with the video
```

This lets Caelestia continue generating the adaptive color scheme from a normal still image while `mpvpaper` provides the visible video wallpaper.

The reference frame may appear very briefly while switching into a video workspace.

## Video cache

Generated video thumbnails and theme-reference frames are cached under:

```text
~/.cache/caelestia-workspace-wallpapers/videos
```

The cache key includes the source video's path, size, and modification time.

Deleting this cache is safe while the utility is closed. Thumbnails will be regenerated the next time they are needed.

## mpvpaper lifecycle

The workspace backend owns the `mpvpaper` process used for each output.

When switching from a video workspace to a still-image workspace, the backend stops the active `mpvpaper` process before applying the next Caelestia wallpaper.

The detached `mpvpaper` process does not inherit the backend's `flock` descriptor, allowing later workspace switches to continue normally.

## Adaptive colors

The app watches Caelestia's generated `scheme.json`.

On a scheme change, the utility performs a short fade-swap so Qt controls do not visibly repaint in a mixture of the old and new light/dark schemes.

## Why the backend only calls `caelestia wallpaper`

Caelestia already handles its adaptive scheme when the wallpaper changes. The backend therefore does not separately call `caelestia scheme`, avoiding duplicate work and race conditions.

For video wallpapers, the selected reference frame is passed through the same `caelestia wallpaper -f` workflow before the video layer starts.

## Closing

Closing the final utility window, including through a Hyprland `SUPER+Q` bind, exits the standalone `qs -c workspace-wallpapers` process.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller deliberately leaves your wallpaper configuration file and generated video cache untouched.

## Scope

This is a local companion utility and is not an official Caelestia component.

No GTK/Thunar theme manipulation is included.
