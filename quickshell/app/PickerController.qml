import QtQuick as QQ
import Quickshell.Hyprland

QQ.QtObject {
    id: picker

    required property var state
    required property var configService
    required property var mediaService
    property var window: null
    property var panel: null
    property var anchorItem: null
    property var target: null
    property bool closing: false
    readonly property bool open: target !== null
    readonly property bool pickingDefault:
        target !== null && target.kind === "default"
    readonly property int selectedWorkspace:
        target !== null && target.kind === "workspace"
            ? Number(target.id) || -1 : -1
    readonly property bool editingExistingWorkspace:
        selectedWorkspace > 0 && state.workspaceHasOverride(selectedWorkspace)

    property bool videoEditorOpen: false
    property string selectedVideoPath: ""
    property real selectedVideoDuration: 0
    property real selectedVideoFrame: 0
    property int selectedVideoInterval: 5
    property var timelineFrames: []
    property bool timelineLoading: false
    property bool videoMatching: false
    property string optimizedVideoPath: ""
    property int optimizedVideoWidth: 0
    property int optimizedVideoHeight: 0

    signal enterRequested()
    signal exitRequested()

    function position() {
        Qt.callLater(function() {
            if (panel && panel.visible && anchorItem)
                panel.anchor.updateAnchor()
        })
    }

    function resetVideoEditor() {
        videoEditorOpen = false
        selectedVideoPath = ""
        selectedVideoDuration = 0
        selectedVideoFrame = 0
        selectedVideoInterval = 5
        timelineFrames = []
        timelineLoading = false
        videoMatching = false
        optimizedVideoPath = ""
        optimizedVideoWidth = 0
        optimizedVideoHeight = 0
        state.mediaError = ""
    }

    function show(newTarget, anchor) {
        closing = false
        anchorItem = anchor
        target = newTarget
        resetVideoEditor()
        mediaService.rescan()
        position()
        enterRequested()
    }

    function openDefault(anchor) {
        if (!videoMatching)
            show({"kind": "default"}, anchor)
    }

    function beginAddWorkspace(anchor) {
        if (!videoMatching)
            show({"kind": "workspace", "id": -1}, anchor)
    }

    function editWorkspace(workspace, anchor) {
        if (!videoMatching)
            show({"kind": "workspace", "id": workspace}, anchor)
    }

    function close() {
        if (videoMatching || !open || closing)
            return
        closing = true
        exitRequested()
    }

    function finalizeClose() {
        target = null
        anchorItem = null
        closing = false
        resetVideoEditor()
    }

    function targetEntry() {
        if (pickingDefault)
            return state.configData.default
        return selectedWorkspace > 0
            ? state.workspaceEntry(selectedWorkspace) : ""
    }

    function preparePendingApply() {
        if (pickingDefault) {
            return Hyprland.focusedWorkspace &&
                    !state.currentWorkspaceHasOverride()
                ? Hyprland.focusedWorkspace.id : -1
        }
        return selectedWorkspace > 0 &&
                state.isCurrentWorkspace(selectedWorkspace)
            ? selectedWorkspace : -1
    }

    function openVideoEditor(item) {
        if (!pickingDefault && selectedWorkspace <= 0)
            return
        const current = targetEntry()
        selectedVideoPath = item.path
        selectedVideoDuration = Number(item.duration) || 0
        if (state.isVideoEntry(current) && state.entryPath(current) === item.path) {
            selectedVideoFrame = state.entryThemeFrame(current)
            selectedVideoInterval = state.entryInterval(current)
        } else {
            selectedVideoFrame = 0
            selectedVideoInterval = 5
        }
        videoEditorOpen = true
        mediaService.loadTimeline()
        position()
    }

    function handleItem(item) {
        if (!pickingDefault && selectedWorkspace <= 0)
            return
        if (item.type === "random")
            configService.assignSimpleEntry(state.randomWallpaperValue)
        else if (item.type === "video")
            openVideoEditor(item)
        else
            configService.assignSimpleEntry(item.path)
    }

    function targetVideoWidth() {
        return window && window.screen
            ? Math.max(2, Math.round(window.screen.width *
                window.screen.devicePixelRatio)) : 1920
    }

    function targetVideoHeight() {
        return window && window.screen
            ? Math.max(2, Math.round(window.screen.height *
                window.screen.devicePixelRatio)) : 1080
    }
}
