import QtQuick as QQ
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config

QQ.QtObject {
    id: state

    readonly property string home: Quickshell.env("HOME")
    readonly property string configPath:
        home + "/.config/caelestia/workspace-wallpapers.json"
    readonly property string schemePath:
        home + "/.local/state/caelestia/scheme.json"
    readonly property string wallpaperStatePath:
        home + "/.local/state/caelestia/wallpaper/path.txt"
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
    property bool transferMatching: false
    property string wallpaperPath: ""
    property real wallLuminance: 0

    readonly property bool light:
        schemeData && String(schemeData.mode || "") === "light"

    function clamp01(value) {
        return Math.max(0, Math.min(1, Number(value) || 0))
    }

    function fileUrl(path) {
        if (!path)
            return ""
        return "file://" +
            encodeURIComponent(String(path)).replace(/%2F/gi, "/")
    }

    function basename(path) {
        const parts = String(path || "").split("/")
        return parts[parts.length - 1]
    }

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

    function rgb(value) {
        let hex = String(value || "").replace("#", "")
        if (hex.length === 3)
            hex = hex.split("").map(character => character + character).join("")
        if (hex.length !== 6)
            return ({r: 0, g: 0, b: 0})

        return ({
            r: parseInt(hex.slice(0, 2), 16) / 255,
            g: parseInt(hex.slice(2, 4), 16) / 255,
            b: parseInt(hex.slice(4, 6), 16) / 255
        })
    }

    function transparencyBase() {
        const configured = GlobalConfig.appearance.transparency.base
        return clamp01(configured - (light ? 0.1 : 0))
    }

    function transparencyLayers() {
        return clamp01(GlobalConfig.appearance.transparency.layers)
    }

    function alterColour(value, alpha, layer) {
        const channels = rgb(value)
        const luminance = Math.sqrt(
            0.299 * channels.r ** 2 +
            0.587 * channels.g ** 2 +
            0.114 * channels.b ** 2
        )

        if (luminance <= 0)
            return Qt.rgba(channels.r, channels.g, channels.b, alpha)

        const offset =
            (!light || layer === 1 ? 1 : -layer / 2) *
            (light ? 0.2 : 0.3) *
            (1 - transparencyBase()) *
            (1 + wallLuminance * (light ? (layer === 1 ? 3 : 1) : 2.5))
        const scale = (luminance + offset) / luminance

        return Qt.rgba(
            clamp01(channels.r * scale),
            clamp01(channels.g * scale),
            clamp01(channels.b * scale),
            alpha
        )
    }

    function layerColour(name, fallback, layer) {
        const value = colour(name, fallback)

        if (!GlobalConfig.appearance.transparency.enabled)
            return value

        const level = layer === undefined ? 1 : Number(layer)
        if (level === 0) {
            const channels = rgb(value)
            return Qt.rgba(
                channels.r, channels.g, channels.b, transparencyBase()
            )
        }

        return alterColour(value, transparencyLayers(), level)
    }

    readonly property var surface:
        layerColour("surface", "#18181d", 0)
    readonly property var surfaceContainer:
        layerColour("surfaceContainer", "#202026", 1)
    readonly property var surfaceContainerLow:
        layerColour("surfaceContainerLow", "#1d1d22", 1)
    readonly property var surfaceContainerHigh:
        layerColour("surfaceContainerHigh", "#292930", 1)
    readonly property var surfaceContainerHighest:
        layerColour("surfaceContainerHighest", "#33333b", 1)
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
    readonly property var error: colour("error", "#ffb4ab")
    readonly property var textError: colour("onError", "#690005")
    readonly property var scrim: colour("scrim", "#000000")

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
            ? "Random wallpaper" : basename(entryPath(entry))
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
