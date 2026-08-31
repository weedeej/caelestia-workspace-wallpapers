-- Add this to the Caelestia Lua config area where `hl` is available.
-- It runs the backend every time the active Hyprland workspace changes.

hl.on("workspace.active", function(workspace)
    hl.exec_cmd(
        os.getenv("HOME") ..
        "/.config/caelestia/scripts/workspace-wallpaper " ..
        tostring(workspace.id)
    )
end)
