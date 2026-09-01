import QtQuick as QQ
import Quickshell
import Quickshell.Hyprland
import "PathUtils.js" as PathUtils

QQ.QtObject {
    id: state

    readonly property string home: Quickshell.env("HOME")
    readonly property string configPath:
        home + "/.config/caelestia/workspace-wallpapers.json"
    readonly property string schemePath:
        home + "/.local/state/caelestia/scheme.json"
    readonly property string helperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-transfer"
    readonly property string applyPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper"
    readonly property string mediaHelperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-media"
    readonly property string randomWallpaperValue: "__CAELESTIA_RANDOM__"

    property var configData: ({"default": "", "workspaces": ({})})
    property var schemeData: ({"colours": ({})})
    property var pendingSchemeData: null
    property bool schemeReady: false
    property var mediaItems: []
    property string configWriteError: ""
    property string mediaError: ""
    property string transferStatus: ""
    property bool transferImporting: false

    function colour(name, fallback) {
        if (schemeData && schemeData.colours &&
                schemeData.colours[name] !== undefined &&
                schemeData.colours[name] !== null) {
            const value = String(schemeData.colours[name])
            if (value.length > 0)
                return value.startsWith("#") ? value : "#" + value
        }
        return fallback
    }

    readonly property var surface: colour("surface", "#18181d")
    readonly property var surfaceContainer:
        colour("surfaceContainer", "#202026")
    readonly property var surfaceContainerLow:
        colour("surfaceContainerLow", "#1d1d22")
    readonly property var surfaceContainerHigh:
        colour("surfaceContainerHigh", "#292930")
    readonly property var surfaceContainerHighest:
        colour("surfaceContainerHighest", "#33333b")
    readonly property var textSurface: colour("onSurface", "#f1f1f4")
    readonly property var textSurfaceVariant:
        colour("onSurfaceVariant", "#b9b9c1")
    readonly property var outline: colour("outline", "#8e8e99")
    readonly property var outlineVariant:
        colour("outlineVariant", "#3d3d46")
    readonly property var primary: colour("primary", "#c9bfff")
    readonly property var textPrimary: colour("onPrimary", "#211a4b")
    readonly property var primaryContainer:
        colour("primaryContainer", "#48406f")
    readonly property var textPrimaryContainer:
        colour("onPrimaryContainer", "#e7deff")

    function entryType(entry) {
        if (entry === undefined || entry === null || entry === "")
            return "none"
        if (typeof entry === "string")
            return entry === randomWallpaperValue ? "random" : "image"
        if (typeof entry === "object" && entry.type)
            return String(entry.type)
        return "none"
    }

    function entryPath(entry) {
        if (typeof entry === "string")
            return entry === randomWallpaperValue ? "" : entry
        if (entry && typeof entry === "object" && entry.path)
            return String(entry.path)
        return ""
    }

    function entryThemeFrame(entry) {
        if (entry && typeof entry === "object" && entry.themeFrame !== undefined)
            return Number(entry.themeFrame) || 0
        return 0
    }

    function entryInterval(entry) {
        if (entry && typeof entry === "object" && entry.interval !== undefined)
            return Math.max(1, Number(entry.interval) || 5)
        return 5
    }

    function isVideoEntry(entry) { return entryType(entry) === "video" }
    function isRandomEntry(entry) { return entryType(entry) === "random" }

    function mediaForPath(path) {
        for (let index = 0; index < mediaItems.length; index++) {
            if (mediaItems[index].path === path)
                return mediaItems[index]
        }
        return null
    }

    function entryPreview(entry) {
        const type = entryType(entry)
        if (type === "image")
            return entryPath(entry)
        if (type === "video") {
            const media = mediaForPath(entryPath(entry))
            return media && media.thumbnail ? media.thumbnail : ""
        }
        return ""
    }

    function entryName(entry) {
        return entryType(entry) === "random"
            ? "Random wallpaper" : PathUtils.basename(entryPath(entry))
    }

    function workspaceHasOverride(workspace) {
        return configData.workspaces &&
            configData.workspaces[workspace.toString()] !== undefined
    }

    function workspaceEntry(workspace) {
        return configData.workspaces
            ? configData.workspaces[workspace.toString()] || "" : ""
    }

    function overrideWorkspaceIds() {
        if (!configData.workspaces)
            return []
        return Object.keys(configData.workspaces).map(value => Number(value))
            .filter(value => value > 0).sort((a, b) => a - b)
    }

    function isCurrentWorkspace(workspace) {
        return Hyprland.focusedWorkspace &&
            Hyprland.focusedWorkspace.id === workspace
    }

    function currentWorkspaceHasOverride() {
        if (!Hyprland.focusedWorkspace)
            return false
        return workspaceHasOverride(Hyprland.focusedWorkspace.id)
    }

    function pickerWorkspaceOptions(selectedWorkspace) {
        const options = ["Select workspace…"]
        for (let workspace = 1; workspace <= 10; workspace++) {
            if (!workspaceHasOverride(workspace) || workspace === selectedWorkspace)
                options.push(String(workspace))
        }
        return options
    }

    function pickerItems(pickingDefault) {
        if (pickingDefault)
            return mediaItems
        return [{"type": "random", "path": "", "thumbnail": "",
            "duration": 0}].concat(mediaItems)
    }
}
