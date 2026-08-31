import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Dialogs as Dialogs
import QtQuick.Layouts as Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets

ShellRoot {
    id: root

    QQ.Connections {
        target: Quickshell

        function onLastWindowClosed() {
            Qt.quit()
        }
    }

    property string home: Quickshell.env("HOME")
    property string imageDir: home + "/Pictures/Wallpapers"
    property string videoDir: home + "/Videos/Wallpapers"

    property string configPath:
        home + "/.config/caelestia/workspace-wallpapers.json"

    property string schemePath:
        home + "/.local/state/caelestia/scheme.json"

    property string helperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-config"

    property string applyPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper"

    property string mediaHelperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-media"

    property string transferHelperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-transfer"

    property var configData: ({
        "default": "",
        "workspaces": ({})
    })

    property var schemeData: ({
        "colours": ({})
    })

    property var pendingSchemeData: null
    property bool schemeReady: false

    property var mediaItems: []

    readonly property string randomWallpaperValue:
        "__CAELESTIA_RANDOM__"

    property bool pickerOpen: false
    property bool pickingDefault: false
    property int selectedWorkspace: -1
    property bool editingExistingWorkspace: false

    property var pendingSelectionValue: null
    property int pendingSelectionWorkspace: -1
    property bool pendingSelectionDefault: false
    property string configWriteError: ""
    property string mediaError: ""
    property string transferStatus: ""
    property bool transferImporting: false

    property bool videoEditorOpen: false
    property string selectedVideoPath: ""
    property real selectedVideoDuration: 0
    property real selectedVideoFrame: 0
    property int selectedVideoInterval: 5
    property var timelineFrames: []
    property bool timelineLoading: false

    function colour(name, fallback) {
        if (
            schemeData &&
            schemeData.colours &&
            schemeData.colours[name] !== undefined &&
            schemeData.colours[name] !== null
        ) {
            const value = String(schemeData.colours[name])

            if (value.length > 0)
                return value.startsWith("#") ? value : "#" + value
        }

        return fallback
    }

    readonly property var surface:
        colour("surface", "#18181d")
    readonly property var surfaceContainer:
        colour("surfaceContainer", "#202026")
    readonly property var surfaceContainerLow:
        colour("surfaceContainerLow", "#1d1d22")
    readonly property var surfaceContainerHigh:
        colour("surfaceContainerHigh", "#292930")
    readonly property var surfaceContainerHighest:
        colour("surfaceContainerHighest", "#33333b")
    readonly property var textSurface:
        colour("onSurface", "#f1f1f4")
    readonly property var textSurfaceVariant:
        colour("onSurfaceVariant", "#b9b9c1")
    readonly property var outline:
        colour("outline", "#8e8e99")
    readonly property var outlineVariant:
        colour("outlineVariant", "#3d3d46")
    readonly property var primary:
        colour("primary", "#c9bfff")
    readonly property var textPrimary:
        colour("onPrimary", "#211a4b")
    readonly property var primaryContainer:
        colour("primaryContainer", "#48406f")
    readonly property var textPrimaryContainer:
        colour("onPrimaryContainer", "#e7deff")

    function fileUrl(path) {
        return path ? "file://" + encodeURI(path) : ""
    }

    function basename(path) {
        if (!path)
            return ""

        const parts = String(path).split("/")
        return parts[parts.length - 1]
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0))
        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)
        const secs = total % 60

        if (hours > 0) {
            return (
                hours.toString().padStart(2, "0") + ":" +
                minutes.toString().padStart(2, "0") + ":" +
                secs.toString().padStart(2, "0")
            )
        }

        return (
            minutes.toString().padStart(2, "0") + ":" +
            secs.toString().padStart(2, "0")
        )
    }

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
        if (
            entry &&
            typeof entry === "object" &&
            entry.themeFrame !== undefined
        )
            return Number(entry.themeFrame) || 0

        return 0
    }

    function entryInterval(entry) {
        if (
            entry &&
            typeof entry === "object" &&
            entry.interval !== undefined
        )
            return Math.max(1, Number(entry.interval) || 5)

        return 5
    }

    function isVideoEntry(entry) {
        return entryType(entry) === "video"
    }

    function isRandomEntry(entry) {
        return entryType(entry) === "random"
    }

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
        const type = entryType(entry)

        if (type === "random")
            return "Random wallpaper"

        const path = entryPath(entry)
        return basename(path)
    }

    function pickerItems() {
        if (pickingDefault)
            return mediaItems

        return [{
            "type": "random",
            "path": "",
            "thumbnail": "",
            "duration": 0
        }].concat(mediaItems)
    }

    function workspaceHasOverride(workspace) {
        return (
            configData.workspaces &&
            configData.workspaces[workspace.toString()] !== undefined
        )
    }

    function workspaceEntry(workspace) {
        if (!configData.workspaces)
            return ""

        return configData.workspaces[workspace.toString()] || ""
    }

    function targetEntry() {
        if (pickingDefault)
            return configData.default

        if (selectedWorkspace > 0)
            return workspaceEntry(selectedWorkspace)

        return ""
    }

    function overrideWorkspaceIds() {
        if (!configData.workspaces)
            return []

        return Object.keys(configData.workspaces)
            .map(value => Number(value))
            .filter(value => value > 0)
            .sort((a, b) => a - b)
    }

    function isCurrentWorkspace(workspace) {
        return (
            Hyprland.focusedWorkspace &&
            Hyprland.focusedWorkspace.id === workspace
        )
    }

    function currentWorkspaceHasOverride() {
        if (!Hyprland.focusedWorkspace)
            return false

        return workspaceHasOverride(Hyprland.focusedWorkspace.id)
    }

    function pickerWorkspaceOptions() {
        const options = ["Select workspace…"]

        for (let workspace = 1; workspace <= 10; workspace++) {
            if (
                !workspaceHasOverride(workspace) ||
                workspace === selectedWorkspace
            )
                options.push(String(workspace))
        }

        return options
    }

    function rescanMedia() {
        if (!mediaScanner.running)
            mediaScanner.exec([mediaHelperPath, "scan"])
    }

    function localPath(fileUrl) {
        const value = String(fileUrl)
        return decodeURIComponent(value.replace(/^file:\/\//, ""))
    }

    function runTransfer(action, fileUrl) {
        if (transferProcess.running || !fileUrl)
            return

        transferStatus = "Working…"
        transferImporting = action.startsWith("import-")
        transferProcess.exec([
            transferHelperPath,
            action,
            localPath(fileUrl)
        ])
    }

    function openExportJsonDialog() {
        const folder = configPath.slice(0, configPath.lastIndexOf("/"))

        exportJsonDialog.currentFolder = fileUrl(folder)
        exportJsonDialog.currentFile = fileUrl(configPath)
        exportJsonDialog.selectedFile = fileUrl(configPath)
        exportJsonDialog.open()
    }

    function scrollPickerIntoView() {
        Qt.callLater(function() {
            const flick = mainScroll.contentItem

            if (
                !flick ||
                flick.contentY === undefined ||
                flick.contentHeight === undefined
            )
                return

            const targetY = Math.max(0, pickerPanel.y - 12)
            const maxY = Math.max(0, flick.contentHeight - flick.height)

            flick.contentY = Math.min(targetY, maxY)
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
        mediaError = ""
    }

    function openDefaultPicker() {
        pickingDefault = true
        selectedWorkspace = -1
        editingExistingWorkspace = false
        pickerOpen = true
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function beginAddWorkspace() {
        pickingDefault = false
        selectedWorkspace = -1
        editingExistingWorkspace = false
        pickerOpen = true
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function editWorkspace(workspace) {
        selectedWorkspace = workspace
        pickingDefault = false
        editingExistingWorkspace = true
        pickerOpen = true
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function clearPendingSelection() {
        pendingSelectionValue = null
        pendingSelectionWorkspace = -1
        pendingSelectionDefault = false
    }

    function closePicker() {
        pickerOpen = false
        pickingDefault = false
        selectedWorkspace = -1
        editingExistingWorkspace = false
        clearPendingSelection()
        resetVideoEditor()
    }

    function entryEquivalent(left, right) {
        const leftType = entryType(left)
        const rightType = entryType(right)

        if (leftType !== rightType)
            return false

        if (leftType === "random")
            return true

        if (leftType === "image")
            return entryPath(left) === entryPath(right)

        if (leftType === "video") {
            return (
                entryPath(left) === entryPath(right) &&
                Math.abs(
                    entryThemeFrame(left) -
                    entryThemeFrame(right)
                ) < 0.01 &&
                entryInterval(left) === entryInterval(right)
            )
        }

        return false
    }

    function confirmPendingSelection() {
        if (pendingSelectionValue === null)
            return

        let saved = false

        if (pendingSelectionDefault) {
            saved = entryEquivalent(
                configData.default,
                pendingSelectionValue
            )
        } else if (
            pendingSelectionWorkspace > 0 &&
            configData.workspaces
        ) {
            saved = entryEquivalent(
                configData.workspaces[
                    pendingSelectionWorkspace.toString()
                ],
                pendingSelectionValue
            )
        }

        if (saved) {
            pickerOpen = false
            clearPendingSelection()
            resetVideoEditor()
        }
    }

    function applyWorkspace(workspace) {
        if (workspace <= 0)
            return

        applyWallpaper.exec([
            applyPath,
            workspace.toString()
        ])
    }

    function preparePendingApply() {
        if (pickingDefault) {
            return (
                Hyprland.focusedWorkspace &&
                !currentWorkspaceHasOverride()
            )
                ? Hyprland.focusedWorkspace.id
                : -1
        }

        return (
            selectedWorkspace > 0 &&
            isCurrentWorkspace(selectedWorkspace)
        )
            ? selectedWorkspace
            : -1
    }

    function assignSimpleEntry(value) {
        if (configWriter.running)
            return

        configWriteError = ""
        pendingSelectionValue = value
        pendingSelectionDefault = pickingDefault
        pendingSelectionWorkspace =
            pickingDefault ? -1 : selectedWorkspace

        configWriter.pendingApplyWorkspace =
            preparePendingApply()

        if (pickingDefault) {
            configWriter.exec([
                helperPath,
                "set-default",
                value
            ])
        } else if (selectedWorkspace > 0) {
            configWriter.exec([
                helperPath,
                "set",
                selectedWorkspace.toString(),
                value
            ])
        }
    }

    function openVideoEditor(item) {
        if (!pickingDefault && selectedWorkspace <= 0)
            return

        const current = targetEntry()

        selectedVideoPath = item.path
        selectedVideoDuration = Number(item.duration) || 0

        if (
            isVideoEntry(current) &&
            entryPath(current) === item.path
        ) {
            selectedVideoFrame = entryThemeFrame(current)
            selectedVideoInterval = entryInterval(current)
        } else {
            selectedVideoFrame = 0
            selectedVideoInterval = 5
        }

        videoEditorOpen = true
        loadTimeline()
        scrollPickerIntoView()
    }

    function loadTimeline() {
        if (!selectedVideoPath || timelineGenerator.running)
            return

        timelineLoading = true
        timelineFrames = []
        mediaError = ""

        timelineGenerator.exec([
            mediaHelperPath,
            "timeline",
            selectedVideoPath,
            selectedVideoInterval.toString()
        ])
    }

    function setTimelinePosition(x, width) {
        if (selectedVideoDuration <= 0 || width <= 0)
            return

        const ratio = Math.max(0, Math.min(1, x / width))
        selectedVideoFrame = ratio * selectedVideoDuration
    }

    function commitVideo() {
        if (
            !selectedVideoPath ||
            (!pickingDefault && selectedWorkspace <= 0) ||
            configWriter.running
        )
            return

        const value = {
            "type": "video",
            "path": selectedVideoPath,
            "themeFrame": Number(selectedVideoFrame.toFixed(3)),
            "interval": selectedVideoInterval
        }

        configWriteError = ""
        pendingSelectionValue = value
        pendingSelectionDefault = pickingDefault
        pendingSelectionWorkspace =
            pickingDefault ? -1 : selectedWorkspace

        configWriter.pendingApplyWorkspace =
            preparePendingApply()

        if (pickingDefault) {
            configWriter.exec([
                helperPath,
                "set-video-default",
                selectedVideoPath,
                value.themeFrame.toString(),
                value.interval.toString()
            ])
        } else {
            configWriter.exec([
                helperPath,
                "set-video",
                selectedWorkspace.toString(),
                selectedVideoPath,
                value.themeFrame.toString(),
                value.interval.toString()
            ])
        }
    }

    function handlePickerItem(item) {
        if (!pickingDefault && selectedWorkspace <= 0)
            return

        if (item.type === "random") {
            assignSimpleEntry(randomWallpaperValue)
        } else if (item.type === "video") {
            openVideoEditor(item)
        } else {
            assignSimpleEntry(item.path)
        }
    }

    function clearWorkspace(workspace) {
        if (workspace <= 0 || configWriter.running)
            return

        configWriter.pendingApplyWorkspace =
            isCurrentWorkspace(workspace)
                ? workspace
                : -1

        configWriter.exec([
            helperPath,
            "clear",
            workspace.toString()
        ])
    }

    FileView {
        id: configFile

        path: root.configPath
        blockLoading: true
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const raw = text()

                if (raw && raw.length > 0) {
                    root.configData = JSON.parse(raw)
                    root.confirmPendingSelection()
                }
            } catch (error) {
                console.warn(
                    "Unable to read workspace wallpaper config:",
                    error
                )
            }
        }
    }

    FileView {
        id: schemeFile

        path: root.schemePath
        blockLoading: true
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const raw = text()

                if (raw && raw.length > 0) {
                    const parsed = JSON.parse(raw)

                    if (!root.schemeReady) {
                        root.schemeData = parsed
                        root.schemeReady = true
                    } else {
                        root.pendingSchemeData = parsed
                        themeSwapAnimation.restart()
                    }
                }
            } catch (error) {
                console.warn(
                    "Unable to read Caelestia scheme:",
                    error
                )
            }
        }
    }

    Process {
        id: configWriter

        property int pendingApplyWorkspace: -1

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    root.configWriteError = message
            }
        }

        onRunningChanged: {
            if (!running) {
                configFile.reload()

                const workspace =
                    pendingApplyWorkspace

                pendingApplyWorkspace = -1

                if (workspace > 0)
                    root.applyWorkspace(workspace)
            }
        }
    }

    Process {
        id: applyWallpaper
    }

    Process {
        id: transferProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    root.transferStatus = message
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    root.transferStatus = message
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0 && root.transferImporting) {
                configFile.reload()
                root.rescanMedia()

                if (Hyprland.focusedWorkspace)
                    root.applyWorkspace(Hyprland.focusedWorkspace.id)
            }

            root.transferImporting = false
        }
    }

    Process {
        id: mediaScanner

        command: [
            root.mediaHelperPath,
            "scan"
        ]

        running: true

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    console.warn("Media scan:", message)
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim()
                    root.mediaItems =
                        raw.length > 0
                            ? JSON.parse(raw)
                            : []
                } catch (error) {
                    console.warn(
                        "Unable to parse media list:",
                        error
                    )
                }
            }
        }
    }

    Process {
        id: timelineGenerator

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    root.mediaError = message
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim()

                    if (raw.length > 0) {
                        const result = JSON.parse(raw)
                        root.timelineFrames =
                            result.frames || []
                        root.selectedVideoDuration =
                            Number(result.duration) || 0

                        if (
                            root.selectedVideoFrame >
                            root.selectedVideoDuration
                        )
                            root.selectedVideoFrame =
                                root.selectedVideoDuration
                    }
                } catch (error) {
                    root.mediaError =
                        "Unable to parse video timeline."
                }

                root.timelineLoading = false
            }
        }
    }

    QQ.SequentialAnimation {
        id: themeSwapAnimation

        QQ.NumberAnimation {
            target: themeLayer
            property: "opacity"
            to: 0.12
            duration: 85
            easing.type: QQ.Easing.InQuad
        }

        QQ.ScriptAction {
            script: {
                if (root.pendingSchemeData !== null) {
                    root.schemeData =
                        root.pendingSchemeData
                    root.pendingSchemeData = null
                }
            }
        }

        QQ.NumberAnimation {
            target: themeLayer
            property: "opacity"
            to: 1
            duration: 170
            easing.type: QQ.Easing.OutCubic
        }
    }

    FloatingWindow {
        id: window

        title: "Workspace Wallpapers"

        implicitWidth: 780
        implicitHeight: 650

        minimumSize:
            Qt.size(580, 480)

        QQ.Rectangle {
            id: themeLayer

            anchors.fill: parent
            color: root.surface

            Dialogs.FileDialog {
                id: importJsonDialog

                title: "Import workspace wallpaper config"
                fileMode: Dialogs.FileDialog.OpenFile
                currentFolder: root.fileUrl(root.home)
                nameFilters: ["JSON config (*.json)"]

                onAccepted:
                    root.runTransfer("import-json", selectedFile)
            }

            Dialogs.FileDialog {
                id: importZipDialog

                title: "Import workspace wallpaper bundle"
                fileMode: Dialogs.FileDialog.OpenFile
                currentFolder: root.fileUrl(root.home)
                nameFilters: ["ZIP bundle (*.zip)"]

                onAccepted:
                    root.runTransfer("import-zip", selectedFile)
            }

            Dialogs.FileDialog {
                id: exportJsonDialog

                title: "Export workspace wallpaper config"
                fileMode: Dialogs.FileDialog.SaveFile
                currentFolder:
                    root.fileUrl(
                        root.configPath.slice(
                            0,
                            root.configPath.lastIndexOf("/")
                        )
                    )
                currentFile: root.fileUrl(root.configPath)
                selectedFile: root.fileUrl(root.configPath)
                defaultSuffix: "json"
                nameFilters: ["JSON config (*.json)"]

                onAccepted:
                    root.runTransfer("export-json", selectedFile)
            }

            Dialogs.FileDialog {
                id: exportZipDialog

                title: "Export workspace wallpaper bundle"
                fileMode: Dialogs.FileDialog.SaveFile
                currentFolder: root.fileUrl(root.home)
                selectedFile:
                    root.fileUrl(root.home + "/workspace-wallpapers.zip")
                defaultSuffix: "zip"
                nameFilters: ["ZIP bundle (*.zip)"]

                onAccepted:
                    root.runTransfer("export-zip", selectedFile)
            }

            Layouts.ColumnLayout {
                anchors.fill: parent
                spacing: 0

                QQ.Rectangle {
                    Layouts.Layout.fillWidth: true
                    Layouts.Layout.preferredHeight: 12

                    color:
                        root.surfaceContainer

                    QQ.MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.SizeAllCursor

                        onPressed:
                            window.startSystemMove()
                    }
                }

                Controls.ScrollView {
                    id: mainScroll

                    Layouts.Layout.fillWidth: true
                    Layouts.Layout.fillHeight: true

                    clip: true

                    QQ.Item {
                        implicitWidth:
                            window.width

                        implicitHeight:
                            content.implicitHeight + 40

                        Layouts.ColumnLayout {
                            id: content

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top

                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            anchors.topMargin: 20

                            spacing: 18

                            Layouts.RowLayout {
                                Layouts.Layout.fillWidth: true
                                spacing: 8

                                Controls.Label {
                                    Layouts.Layout.fillWidth: true

                                    text: root.transferStatus
                                    color: root.textSurfaceVariant
                                    font.pixelSize: 11
                                    elide: QQ.Text.ElideRight
                                }

                                QQ.Row {
                                    id: transferSplitButton

                                    spacing: 3

                                    QQ.Rectangle {
                                        id: importJsonButton

                                        width: 154
                                        height: 42
                                        radius: 21

                                        color:
                                            !importJsonMouse.enabled
                                                ? Qt.alpha(root.primary, 0.38)
                                                : importJsonMouse.pressed
                                                    ? Qt.darker(root.primary, 1.12)
                                                    : importJsonMouse.containsMouse
                                                        ? Qt.lighter(root.primary, 1.06)
                                                        : root.primary

                                        Layouts.RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Controls.Label {
                                                text: "file_open"
                                                color:
                                                    importJsonMouse.enabled
                                                        ? root.textPrimary
                                                        : Qt.alpha(root.textSurface, 0.38)
                                                font.family:
                                                    "Material Symbols Rounded"
                                                font.pixelSize: 19
                                            }

                                            Controls.Label {
                                                text: "Import (JSON)"
                                                color:
                                                    importJsonMouse.enabled
                                                        ? root.textPrimary
                                                        : Qt.alpha(root.textSurface, 0.38)
                                                font.pixelSize: 13
                                                font.weight: 600
                                            }
                                        }

                                        QQ.MouseArea {
                                            id: importJsonMouse

                                            anchors.fill: parent
                                            enabled: !transferProcess.running
                                            hoverEnabled: true
                                            cursorShape:
                                                enabled
                                                    ? Qt.PointingHandCursor
                                                    : Qt.ArrowCursor

                                            onClicked:
                                                importJsonDialog.open()

                                            Controls.ToolTip.visible:
                                                containsMouse

                                            Controls.ToolTip.delay: 500

                                            Controls.ToolTip.text:
                                                "Import only a workspace wallpapers config."
                                        }

                                        QQ.Behavior on color {
                                            QQ.ColorAnimation {
                                                duration: 120
                                            }
                                        }
                                    }

                                    QQ.Rectangle {
                                        id: transferMenuButton

                                        width: 42
                                        height: 42
                                        radius: 21

                                        color:
                                            !transferMenuMouse.enabled
                                                ? Qt.alpha(root.primary, 0.38)
                                                : transferMenuMouse.pressed
                                                    ? Qt.darker(root.primary, 1.12)
                                                    : transferMenu.visible || transferMenuMouse.containsMouse
                                                        ? Qt.lighter(root.primary, 1.06)
                                                        : root.primary

                                        Controls.Label {
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: 1

                                            text: "expand_more"
                                            color:
                                                transferMenuMouse.enabled
                                                    ? root.textPrimary
                                                    : Qt.alpha(root.textSurface, 0.38)
                                            font.family:
                                                "Material Symbols Rounded"
                                            font.pixelSize: 21
                                            rotation:
                                                transferMenu.visible ? 180 : 0

                                            QQ.Behavior on rotation {
                                                QQ.NumberAnimation {
                                                    duration: 160
                                                }
                                            }
                                        }

                                        QQ.MouseArea {
                                            id: transferMenuMouse

                                            anchors.fill: parent
                                            enabled: !transferProcess.running
                                            hoverEnabled: true
                                            cursorShape:
                                                enabled
                                                    ? Qt.PointingHandCursor
                                                    : Qt.ArrowCursor

                                            onClicked: {
                                                const point =
                                                    transferSplitButton.mapToItem(
                                                        themeLayer,
                                                        0,
                                                        transferSplitButton.height + 8
                                                    )

                                                transferMenu.x =
                                                    themeLayer.width - transferMenu.width - 20
                                                transferMenu.y = point.y
                                                transferMenu.open()
                                            }

                                            Controls.ToolTip.visible:
                                                containsMouse &&
                                                !transferMenu.visible

                                            Controls.ToolTip.delay: 500

                                            Controls.ToolTip.text:
                                                "More import and export actions."
                                        }

                                        QQ.Behavior on color {
                                            QQ.ColorAnimation {
                                                duration: 120
                                            }
                                        }

                                        Controls.Popup {
                                            id: transferMenu

                                            parent: themeLayer
                                            x:
                                                themeLayer.width - width - 20
                                            y:
                                                transferSplitButton.mapToItem(
                                                    themeLayer,
                                                    0,
                                                    transferSplitButton.height + 8
                                                ).y

                                            width: 350
                                            height: 210
                                            padding: 0
                                            popupType: Controls.Popup.Item
                                            closePolicy:
                                                Controls.Popup.CloseOnEscape |
                                                Controls.Popup.CloseOnPressOutside

                                            background: QQ.Rectangle {
                                                radius: 16
                                                color:
                                                    root.surfaceContainerLow
                                                border.width: 1
                                                border.color:
                                                    root.outlineVariant
                                            }

                                            Controls.MenuItem {
                                                id: importZipMenuItem

                                                text: "Import (ZIP)"
                                                x: 6
                                                y: 6
                                                width: transferMenu.width - 12
                                                height: 66
                                                leftPadding: 12
                                                rightPadding: 12
                                                hoverEnabled: true

                                                background: QQ.Rectangle {
                                                    radius: 11
                                                    color:
                                                        importZipMenuItem.highlighted || importZipMenuItem.hovered
                                                            ? root.primaryContainer
                                                            : "transparent"
                                                }

                                                contentItem: Layouts.RowLayout {
                                                    spacing: 11

                                                    Controls.Label {
                                                        text: "folder_zip"
                                                        color:
                                                            importZipMenuItem.highlighted || importZipMenuItem.hovered
                                                                ? root.textPrimaryContainer
                                                                : root.textSurfaceVariant
                                                        font.family:
                                                            "Material Symbols Rounded"
                                                        font.pixelSize: 19
                                                    }

                                                    Layouts.ColumnLayout {
                                                        Layouts.Layout.fillWidth: true
                                                        spacing: 2

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text: importZipMenuItem.text
                                                            color:
                                                                importZipMenuItem.highlighted || importZipMenuItem.hovered
                                                                    ? root.textPrimaryContainer
                                                                    : root.textSurface
                                                            font.pixelSize: 13
                                                            font.weight: 600
                                                        }

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text:
                                                                "Import config, images, and videos from a ZIP bundle."
                                                            color:
                                                                importZipMenuItem.highlighted || importZipMenuItem.hovered
                                                                    ? Qt.alpha(root.textPrimaryContainer, 0.78)
                                                                    : root.textSurfaceVariant
                                                            font.pixelSize: 11
                                                            elide: QQ.Text.ElideRight
                                                        }
                                                    }
                                                }

                                                onClicked: {
                                                    transferMenu.close()
                                                    importZipDialog.open()
                                                }

                                            }

                                            Controls.MenuItem {
                                                id: exportJsonMenuItem

                                                text: "Export (JSON)"
                                                x: 6
                                                y: 72
                                                width: transferMenu.width - 12
                                                height: 66
                                                leftPadding: 12
                                                rightPadding: 12
                                                hoverEnabled: true

                                                background: QQ.Rectangle {
                                                    radius: 11
                                                    color:
                                                        exportJsonMenuItem.highlighted || exportJsonMenuItem.hovered
                                                            ? root.primaryContainer
                                                            : "transparent"
                                                }

                                                contentItem: Layouts.RowLayout {
                                                    spacing: 11

                                                    Controls.Label {
                                                        text: "data_object"
                                                        color:
                                                            exportJsonMenuItem.highlighted || exportJsonMenuItem.hovered
                                                                ? root.textPrimaryContainer
                                                                : root.textSurfaceVariant
                                                        font.family:
                                                            "Material Symbols Rounded"
                                                        font.pixelSize: 19
                                                    }

                                                    Layouts.ColumnLayout {
                                                        Layouts.Layout.fillWidth: true
                                                        spacing: 2

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text: exportJsonMenuItem.text
                                                            color:
                                                                exportJsonMenuItem.highlighted || exportJsonMenuItem.hovered
                                                                    ? root.textPrimaryContainer
                                                                    : root.textSurface
                                                            font.pixelSize: 13
                                                            font.weight: 600
                                                        }

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text: "Export only the config."
                                                            color:
                                                                exportJsonMenuItem.highlighted || exportJsonMenuItem.hovered
                                                                    ? Qt.alpha(root.textPrimaryContainer, 0.78)
                                                                    : root.textSurfaceVariant
                                                            font.pixelSize: 11
                                                            elide: QQ.Text.ElideRight
                                                        }
                                                    }
                                                }

                                                onClicked: {
                                                    transferMenu.close()
                                                    root.openExportJsonDialog()
                                                }

                                            }

                                            Controls.MenuItem {
                                                id: exportZipMenuItem

                                                text: "Export (ZIP)"
                                                x: 6
                                                y: 138
                                                width: transferMenu.width - 12
                                                height: 66
                                                leftPadding: 12
                                                rightPadding: 12
                                                hoverEnabled: true

                                                background: QQ.Rectangle {
                                                    radius: 11
                                                    color:
                                                        exportZipMenuItem.highlighted || exportZipMenuItem.hovered
                                                            ? root.primaryContainer
                                                            : "transparent"
                                                }

                                                contentItem: Layouts.RowLayout {
                                                    spacing: 11

                                                    Controls.Label {
                                                        text: "archive"
                                                        color:
                                                            exportZipMenuItem.highlighted || exportZipMenuItem.hovered
                                                                ? root.textPrimaryContainer
                                                                : root.textSurfaceVariant
                                                        font.family:
                                                            "Material Symbols Rounded"
                                                        font.pixelSize: 19
                                                    }

                                                    Layouts.ColumnLayout {
                                                        Layouts.Layout.fillWidth: true
                                                        spacing: 2

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text: exportZipMenuItem.text
                                                            color:
                                                                exportZipMenuItem.highlighted || exportZipMenuItem.hovered
                                                                    ? root.textPrimaryContainer
                                                                    : root.textSurface
                                                            font.pixelSize: 13
                                                            font.weight: 600
                                                        }

                                                        Controls.Label {
                                                            Layouts.Layout.fillWidth: true
                                                            text:
                                                                "Export config with all media assets in use."
                                                            color:
                                                                exportZipMenuItem.highlighted || exportZipMenuItem.hovered
                                                                    ? Qt.alpha(root.textPrimaryContainer, 0.78)
                                                                    : root.textSurfaceVariant
                                                            font.pixelSize: 11
                                                            elide: QQ.Text.ElideRight
                                                        }
                                                    }
                                                }

                                                onClicked: {
                                                    transferMenu.close()
                                                    exportZipDialog.open()
                                                }

                                            }
                                        }
                                    }
                                }
                            }

                            Controls.Label {
                                text:
                                    "DEFAULT  (all non-custom use this)"

                                color:
                                    root.textSurfaceVariant

                                font.pixelSize: 12
                                font.bold: true
                            }

                            ClippingRectangle {
                                id: defaultPreview

                                property var entry:
                                    root.configData.default

                                Layouts.Layout.fillWidth: true
                                Layouts.Layout.preferredHeight: 180

                                radius: 16
                                color:
                                    root.surfaceContainerHigh

                                QQ.Image {
                                    anchors.fill: parent

                                    visible:
                                        root.entryPreview(
                                            defaultPreview.entry
                                        ).length > 0

                                    source:
                                        root.fileUrl(
                                            root.entryPreview(
                                                defaultPreview.entry
                                            )
                                        )

                                    fillMode:
                                        QQ.Image.PreserveAspectCrop

                                    asynchronous: true
                                    smooth: true
                                }

                                QQ.Rectangle {
                                    anchors.centerIn: parent

                                    visible:
                                        root.isVideoEntry(
                                            defaultPreview.entry
                                        ) &&
                                        root.entryPreview(
                                            defaultPreview.entry
                                        ).length === 0

                                    width: 64
                                    height: 64
                                    radius: 32
                                    color:
                                        root.primaryContainer

                                    Controls.Label {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        color:
                                            root.textPrimaryContainer
                                        font.pixelSize: 24
                                    }
                                }

                                QQ.Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 10

                                    visible:
                                        root.isVideoEntry(
                                            defaultPreview.entry
                                        )

                                    width: 56
                                    height: 24
                                    radius: 12
                                    color:
                                        Qt.rgba(0, 0, 0, 0.62)

                                    Controls.Label {
                                        anchors.centerIn: parent
                                        text: "▶ VIDEO"
                                        color: "white"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                QQ.HoverHandler {
                                    id: defaultHover
                                }

                                QQ.Rectangle {
                                    anchors.fill: parent
                                    anchors.bottomMargin: 52

                                    visible:
                                        defaultHover.hovered

                                    color:
                                        Qt.rgba(0, 0, 0, 0.26)

                                    QQ.Rectangle {
                                        anchors.centerIn: parent

                                        width: 42
                                        height: 42
                                        radius: 21

                                        color:
                                            root.primaryContainer

                                        Controls.Label {
                                            anchors.centerIn: parent
                                            text: "✎"
                                            color:
                                                root.textPrimaryContainer
                                            font.pixelSize: 21
                                            font.bold: true
                                        }

                                        QQ.MouseArea {
                                            anchors.fill: parent
                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                root.openDefaultPicker()
                                        }
                                    }
                                }

                                QQ.Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    height: 52

                                    color:
                                        Qt.rgba(
                                            0,
                                            0,
                                            0,
                                            0.62
                                        )

                                    Controls.Label {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        anchors.leftMargin: 15
                                        anchors.rightMargin: 15

                                        text:
                                            root.entryName(
                                                defaultPreview.entry
                                            )

                                        color: "white"

                                        elide:
                                            QQ.Text.ElideMiddle
                                    }
                                }
                            }

                            Layouts.RowLayout {
                                Layouts.Layout.fillWidth: true
                                spacing: 8

                                Controls.Label {
                                    text: "WORKSPACES"

                                    color:
                                        root.textSurfaceVariant

                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Controls.Button {
                                    text: "+ Add"
                                    flat: true

                                    palette.buttonText:
                                        root.primary

                                    onClicked:
                                        root.beginAddWorkspace()
                                }

                                QQ.Item {
                                    Layouts.Layout.fillWidth: true
                                }
                            }

                            QQ.Flow {
                                id: workspaceFlow

                                Layouts.Layout.fillWidth: true
                                spacing: 14

                                readonly property int columnCount:
                                    Math.max(
                                        1,
                                        Math.floor(
                                            (width + spacing) / (160 + spacing)
                                        )
                                    )

                                readonly property real cardWidth:
                                    (width - (columnCount - 1) * spacing)
                                    / columnCount

                                QQ.Repeater {
                                    model:
                                        root.overrideWorkspaceIds()

                                    delegate: QQ.Item {
                                        id: workspaceCard

                                        required property var modelData

                                        property int workspace:
                                            Number(modelData)

                                        property var entry:
                                            root.workspaceEntry(
                                                workspace
                                            )

                                        width: workspaceFlow.cardWidth
                                        height: 138

                                        Layouts.ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Controls.Label {
                                                text:
                                                    "Workspace " +
                                                    workspaceCard.workspace

                                                color:
                                                    root.textSurface

                                                font.pixelSize: 13

                                                font.bold:
                                                    root.isCurrentWorkspace(
                                                        workspaceCard.workspace
                                                    )
                                            }

                                            ClippingRectangle {
                                                Layouts.Layout.fillWidth: true
                                                Layouts.Layout.fillHeight: true

                                                radius: 12

                                                color:
                                                    root.surfaceContainerHigh

                                                border.width:
                                                    root.isCurrentWorkspace(
                                                        workspaceCard.workspace
                                                    )
                                                        ? 2
                                                        : 0

                                                border.color:
                                                    root.primary

                                                QQ.Image {
                                                    anchors.fill: parent

                                                    visible:
                                                        root.entryPreview(
                                                            workspaceCard.entry
                                                        ).length > 0

                                                    source:
                                                        root.fileUrl(
                                                            root.entryPreview(
                                                                workspaceCard.entry
                                                            )
                                                        )

                                                    fillMode:
                                                        QQ.Image.PreserveAspectCrop

                                                    asynchronous: true
                                                    smooth: true
                                                }

                                                QQ.Rectangle {
                                                    anchors.fill: parent

                                                    visible:
                                                        root.isRandomEntry(
                                                            workspaceCard.entry
                                                        )

                                                    color:
                                                        root.primaryContainer

                                                    QQ.Rectangle {
                                                        anchors.centerIn: parent

                                                        width: 42
                                                        height: 42
                                                        radius: 9

                                                        color:
                                                            root.textPrimaryContainer

                                                        QQ.Repeater {
                                                            model: [
                                                                [9, 9],
                                                                [27, 9],
                                                                [18, 18],
                                                                [9, 27],
                                                                [27, 27]
                                                            ]

                                                            delegate: QQ.Rectangle {
                                                                required property var modelData

                                                                width: 6
                                                                height: 6
                                                                radius: 3
                                                                x: modelData[0]
                                                                y: modelData[1]

                                                                color:
                                                                    root.primaryContainer
                                                            }
                                                        }
                                                    }
                                                }

                                                QQ.Rectangle {
                                                    anchors.centerIn: parent

                                                    visible:
                                                        root.isVideoEntry(
                                                            workspaceCard.entry
                                                        ) &&
                                                        root.entryPreview(
                                                            workspaceCard.entry
                                                        ).length === 0

                                                    width: 46
                                                    height: 46
                                                    radius: 23

                                                    color:
                                                        root.primaryContainer

                                                    Controls.Label {
                                                        anchors.centerIn: parent
                                                        text: "▶"
                                                        color:
                                                            root.textPrimaryContainer
                                                        font.pixelSize: 18
                                                    }
                                                }

                                                QQ.Rectangle {
                                                    anchors.top: parent.top
                                                    anchors.left: parent.left
                                                    anchors.margins: 7

                                                    visible:
                                                        root.isVideoEntry(
                                                            workspaceCard.entry
                                                        )

                                                    width: 24
                                                    height: 24
                                                    radius: 12

                                                    color:
                                                        Qt.rgba(
                                                            0,
                                                            0,
                                                            0,
                                                            0.62
                                                        )

                                                    Controls.Label {
                                                        anchors.centerIn: parent
                                                        text: "▶"
                                                        color: "white"
                                                        font.pixelSize: 10
                                                    }
                                                }

                                                QQ.HoverHandler {
                                                    id: workspaceHover
                                                }

                                                QQ.Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom

                                                    height: 36

                                                    color:
                                                        Qt.rgba(
                                                            0,
                                                            0,
                                                            0,
                                                            0.63
                                                        )

                                                    Controls.Label {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter:
                                                            parent.verticalCenter

                                                        anchors.leftMargin: 9
                                                        anchors.rightMargin: 9

                                                        text:
                                                            root.entryName(
                                                                workspaceCard.entry
                                                            )

                                                        color: "white"
                                                        font.pixelSize: 10
                                                        elide:
                                                            QQ.Text.ElideMiddle
                                                    }
                                                }

                                                QQ.Rectangle {
                                                    anchors.fill: parent
                                                    anchors.bottomMargin: 36

                                                    visible:
                                                        workspaceHover.hovered

                                                    color:
                                                        Qt.rgba(
                                                            0,
                                                            0,
                                                            0,
                                                            0.34
                                                        )

                                                    QQ.Rectangle {
                                                        anchors.left:
                                                            parent.left

                                                        anchors.verticalCenter:
                                                            parent.verticalCenter

                                                        anchors.leftMargin: 12

                                                        width: 38
                                                        height: 38
                                                        radius: 19

                                                        color:
                                                            root.primaryContainer

                                                        Controls.Label {
                                                            anchors.centerIn: parent
                                                            text: "✎"
                                                            color:
                                                                root.textPrimaryContainer
                                                            font.pixelSize: 19
                                                            font.bold: true
                                                        }

                                                        QQ.MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape:
                                                                Qt.PointingHandCursor

                                                            onClicked:
                                                                root.editWorkspace(
                                                                    workspaceCard.workspace
                                                                )
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.right:
                                                            parent.right

                                                        anchors.verticalCenter:
                                                            parent.verticalCenter

                                                        anchors.rightMargin: 12

                                                        width: 38
                                                        height: 38
                                                        radius: 19

                                                        color:
                                                            Qt.rgba(
                                                                0,
                                                                0,
                                                                0,
                                                                0.34
                                                            )

                                                        QQ.Item {
                                                            anchors.centerIn: parent
                                                            width: 18
                                                            height: 20

                                                            readonly property var trashRed:
                                                                "#ef4444"

                                                            QQ.Rectangle {
                                                                x: 4
                                                                y: 5
                                                                width: 10
                                                                height: 12
                                                                radius: 2
                                                                color:
                                                                    parent.trashRed
                                                            }

                                                            QQ.Rectangle {
                                                                x: 2
                                                                y: 3
                                                                width: 14
                                                                height: 3
                                                                radius: 1
                                                                color:
                                                                    parent.trashRed
                                                            }

                                                            QQ.Rectangle {
                                                                x: 6
                                                                y: 0
                                                                width: 6
                                                                height: 4
                                                                radius: 1
                                                                color:
                                                                    parent.trashRed
                                                            }
                                                        }

                                                        QQ.MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape:
                                                                Qt.PointingHandCursor

                                                            onClicked:
                                                                root.clearWorkspace(
                                                                    workspaceCard.workspace
                                                                )
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            QQ.Rectangle {
                                id: pickerPanel

                                visible:
                                    root.pickerOpen

                                Layouts.Layout.fillWidth: true

                                Layouts.Layout.preferredHeight:
                                    root.videoEditorOpen
                                        ? 520
                                        : 330

                                radius: 14

                                color:
                                    root.surfaceContainer

                                border.width: 1
                                border.color:
                                    root.outlineVariant

                                Layouts.ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Layouts.RowLayout {
                                        Layouts.Layout.fillWidth: true
                                        spacing: 8

                                        Controls.Label {
                                            visible:
                                                root.pickingDefault

                                            text:
                                                "Choose default wallpaper"

                                            color:
                                                root.textSurface

                                            font.bold: true
                                        }

                                        Controls.Label {
                                            visible:
                                                !root.pickingDefault

                                            text:
                                                "Choose wallpaper for workspace:"

                                            color:
                                                root.textSurface

                                            font.bold: true
                                        }

                                        QQ.Rectangle {
                                            visible:
                                                !root.pickingDefault &&
                                                root.editingExistingWorkspace

                                            Layouts.Layout.preferredWidth: 58
                                            Layouts.Layout.preferredHeight: 32

                                            radius: 8

                                            color:
                                                root.surfaceContainerHigh

                                            border.width: 1

                                            border.color:
                                                root.outlineVariant

                                            Controls.Label {
                                                anchors.centerIn: parent

                                                text:
                                                    root.selectedWorkspace > 0
                                                        ? root.selectedWorkspace.toString()
                                                        : ""

                                                color:
                                                    root.primary

                                                font.bold: true
                                            }
                                        }

                                        Controls.ComboBox {
                                            id: workspaceCombo

                                            visible:
                                                !root.pickingDefault &&
                                                !root.editingExistingWorkspace

                                            Layouts.Layout.preferredWidth:
                                                194

                                            Layouts.Layout.preferredHeight:
                                                42

                                            leftPadding: 14
                                            rightPadding: 42

                                            model:
                                                root.pickerWorkspaceOptions()

                                            currentIndex: {
                                                if (root.selectedWorkspace <= 0)
                                                    return 0

                                                const options =
                                                    root.pickerWorkspaceOptions()

                                                const optionIndex =
                                                    options.indexOf(
                                                        String(
                                                            root.selectedWorkspace
                                                        )
                                                    )

                                                return optionIndex >= 0
                                                    ? optionIndex
                                                    : 0
                                            }

                                            contentItem: Layouts.RowLayout {
                                                spacing: 9

                                                Controls.Label {
                                                    text: "grid_view"
                                                    color:
                                                        workspaceCombo.currentIndex > 0
                                                            ? root.primary
                                                            : root.textSurfaceVariant
                                                    font.family:
                                                        "Material Symbols Rounded"
                                                    font.pixelSize: 18
                                                }

                                                Controls.Label {
                                                    Layouts.Layout.fillWidth: true

                                                    text:
                                                        workspaceCombo.currentIndex > 0
                                                            ? "Workspace " + workspaceCombo.displayText
                                                            : workspaceCombo.displayText
                                                    color:
                                                        workspaceCombo.currentIndex > 0
                                                            ? root.textSurface
                                                            : root.textSurfaceVariant
                                                    font.pixelSize: 13
                                                    font.weight:
                                                        workspaceCombo.currentIndex > 0
                                                            ? 600
                                                            : 400
                                                    elide: QQ.Text.ElideRight
                                                    verticalAlignment:
                                                        QQ.Text.AlignVCenter
                                                }
                                            }

                                            indicator: Controls.Label {
                                                x:
                                                    workspaceCombo.width - width - 13
                                                y:
                                                    workspaceCombo.topPadding +
                                                    (workspaceCombo.availableHeight - height) / 2

                                                text: "expand_more"
                                                color: root.textSurfaceVariant
                                                font.family:
                                                    "Material Symbols Rounded"
                                                font.pixelSize: 21
                                                rotation:
                                                    workspaceCombo.popup.visible
                                                        ? 180
                                                        : 0

                                                QQ.Behavior on rotation {
                                                    QQ.NumberAnimation {
                                                        duration: 160
                                                    }
                                                }
                                            }

                                            background: QQ.Rectangle {
                                                radius: 21
                                                color:
                                                    workspaceCombo.pressed
                                                        ? root.surfaceContainerHighest
                                                        : workspaceCombo.hovered || workspaceCombo.popup.visible
                                                            ? root.surfaceContainerHigh
                                                            : root.surfaceContainerLow
                                                border.width:
                                                    workspaceCombo.popup.visible
                                                        ? 2
                                                        : 1
                                                border.color:
                                                    workspaceCombo.popup.visible
                                                        ? root.primary
                                                        : workspaceCombo.hovered
                                                            ? root.outline
                                                            : root.outlineVariant

                                                QQ.Behavior on color {
                                                    QQ.ColorAnimation {
                                                        duration: 120
                                                    }
                                                }

                                                QQ.Behavior on border.color {
                                                    QQ.ColorAnimation {
                                                        duration: 120
                                                    }
                                                }
                                            }

                                            delegate: Controls.ItemDelegate {
                                                id: workspaceOption

                                                required property var modelData
                                                required property int index

                                                width:
                                                    workspaceCombo.popup.width - 12
                                                height: 42
                                                leftPadding: 11
                                                rightPadding: 11

                                                highlighted:
                                                    workspaceCombo.highlightedIndex === index

                                                background: QQ.Rectangle {
                                                    radius: 11
                                                    color:
                                                        workspaceOption.highlighted
                                                            ? root.primaryContainer
                                                            : "transparent"
                                                }

                                                contentItem: Layouts.RowLayout {
                                                    spacing: 9

                                                    Controls.Label {
                                                        text:
                                                            workspaceOption.index === workspaceCombo.currentIndex
                                                                ? "check"
                                                                : workspaceOption.index === 0
                                                                    ? "select_check_box"
                                                                    : "grid_view"
                                                        color:
                                                            workspaceOption.highlighted
                                                                ? root.textPrimaryContainer
                                                                : workspaceOption.index === workspaceCombo.currentIndex
                                                                    ? root.primary
                                                                    : root.textSurfaceVariant
                                                        font.family:
                                                            "Material Symbols Rounded"
                                                        font.pixelSize: 18
                                                    }

                                                    Controls.Label {
                                                        Layouts.Layout.fillWidth: true

                                                        text:
                                                            workspaceOption.index > 0
                                                                ? "Workspace " + workspaceOption.modelData
                                                                : workspaceOption.modelData
                                                        color:
                                                            workspaceOption.highlighted
                                                                ? root.textPrimaryContainer
                                                                : root.textSurface
                                                        font.pixelSize: 13
                                                    }
                                                }
                                            }

                                            popup: Controls.Popup {
                                                y: workspaceCombo.height + 8
                                                width: workspaceCombo.width
                                                padding: 6

                                                implicitHeight:
                                                    Math.min(
                                                        contentItem.implicitHeight + 12,
                                                        280
                                                    )

                                                contentItem: QQ.ListView {
                                                    clip: true
                                                    implicitHeight: contentHeight
                                                    model:
                                                        workspaceCombo.popup.visible
                                                            ? workspaceCombo.delegateModel
                                                            : null
                                                    currentIndex:
                                                        workspaceCombo.highlightedIndex
                                                    highlightMoveDuration: 0

                                                    Controls.ScrollIndicator.vertical:
                                                        Controls.ScrollIndicator {}
                                                }

                                                background: QQ.Rectangle {
                                                    radius: 16
                                                    color:
                                                        root.surfaceContainerLow
                                                    border.width: 1
                                                    border.color:
                                                        root.outlineVariant
                                                }
                                            }

                                            onActivated: {
                                                root.resetVideoEditor()

                                                if (currentIndex <= 0) {
                                                    root.selectedWorkspace = -1
                                                } else {
                                                    root.selectedWorkspace =
                                                        Number(
                                                            model[currentIndex]
                                                        )
                                                }
                                            }
                                        }

                                        QQ.Item {
                                            Layouts.Layout.fillWidth: true
                                        }

                                        Controls.Button {
                                            text: "Refresh"
                                            flat: true

                                            palette.buttonText:
                                                root.primary

                                            onClicked:
                                                root.rescanMedia()
                                        }

                                        Controls.Button {
                                            text: "Cancel"
                                            flat: true

                                            palette.buttonText:
                                                root.primary

                                            onClicked:
                                                root.closePicker()
                                        }
                                    }

                                    Controls.Label {
                                        visible:
                                            !root.pickingDefault &&
                                            root.selectedWorkspace <= 0

                                        Layouts.Layout.fillWidth: true

                                        text:
                                            "Select a workspace to enable wallpaper selection."

                                        color:
                                            root.textSurfaceVariant

                                        font.pixelSize: 11
                                    }

                                    Controls.Label {
                                        visible:
                                            root.configWriteError.length > 0

                                        Layouts.Layout.fillWidth: true

                                        text:
                                            root.configWriteError

                                        color: "#ef4444"
                                        font.pixelSize: 11
                                        wrapMode:
                                            QQ.Text.Wrap
                                    }

                                    Controls.Label {
                                        visible:
                                            root.mediaError.length > 0

                                        Layouts.Layout.fillWidth: true

                                        text:
                                            root.mediaError

                                        color: "#ef4444"
                                        font.pixelSize: 11
                                        wrapMode:
                                            QQ.Text.Wrap
                                    }

                                    QQ.Rectangle {
                                        visible:
                                            root.videoEditorOpen

                                        Layouts.Layout.fillWidth: true
                                        Layouts.Layout.preferredHeight: 180

                                        radius: 12
                                        color:
                                            root.surfaceContainerLow

                                        border.width: 1
                                        border.color:
                                            root.outlineVariant

                                        Layouts.ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 8

                                            Layouts.RowLayout {
                                                Layouts.Layout.fillWidth: true

                                                Controls.Label {
                                                    Layouts.Layout.fillWidth: true

                                                    text:
                                                        root.basename(
                                                            root.selectedVideoPath
                                                        )

                                                    color:
                                                        root.textSurface

                                                    font.bold: true

                                                    elide:
                                                        QQ.Text.ElideMiddle
                                                }

                                                Controls.Label {
                                                    text:
                                                        root.formatTime(
                                                            root.selectedVideoDuration
                                                        )

                                                    color:
                                                        root.textSurfaceVariant

                                                    font.pixelSize: 11
                                                }

                                                Controls.Label {
                                                    text:
                                                        "Frames every"

                                                    color:
                                                        root.textSurfaceVariant

                                                    font.pixelSize: 11
                                                }

                                                Controls.ComboBox {
                                                    id: intervalCombo

                                                    enabled:
                                                        !root.timelineLoading

                                                    Layouts.Layout.preferredWidth: 84

                                                    model:
                                                        [1, 2, 5, 10, 15, 30]

                                                    currentIndex: {
                                                        const index =
                                                            model.indexOf(
                                                                root.selectedVideoInterval
                                                            )

                                                        return index >= 0
                                                            ? index
                                                            : 2
                                                    }

                                                    palette.button:
                                                        root.surfaceContainerHigh

                                                    palette.buttonText:
                                                        root.textSurface

                                                    onActivated: {
                                                        root.selectedVideoInterval =
                                                            Number(
                                                                model[currentIndex]
                                                            )

                                                        root.loadTimeline()
                                                    }
                                                }

                                                Controls.Label {
                                                    text: "sec"
                                                    color:
                                                        root.textSurfaceVariant
                                                    font.pixelSize: 11
                                                }
                                            }

                                            QQ.Rectangle {
                                                id: timelineTrack

                                                Layouts.Layout.fillWidth: true
                                                Layouts.Layout.preferredHeight: 86

                                                radius: 9
                                                clip: true

                                                color:
                                                    root.surfaceContainerHigh

                                                QQ.Repeater {
                                                    model:
                                                        root.timelineFrames

                                                    delegate: QQ.Image {
                                                        required property var modelData
                                                        required property int index

                                                        width:
                                                            timelineTrack.width /
                                                            Math.max(
                                                                1,
                                                                root.timelineFrames.length
                                                            )

                                                        height:
                                                            timelineTrack.height

                                                        x:
                                                            index * width

                                                        source:
                                                            root.fileUrl(
                                                                modelData.path
                                                            )

                                                        fillMode:
                                                            QQ.Image.PreserveAspectCrop

                                                        asynchronous: true
                                                        smooth: true
                                                    }
                                                }

                                                QQ.Rectangle {
                                                    anchors.fill: parent

                                                    visible:
                                                        root.timelineLoading

                                                    color:
                                                        Qt.rgba(
                                                            0,
                                                            0,
                                                            0,
                                                            0.42
                                                        )

                                                    Controls.Label {
                                                        anchors.centerIn: parent
                                                        text:
                                                            "Generating frame track…"
                                                        color: "white"
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                QQ.Rectangle {
                                                    id: timelineHandle

                                                    visible:
                                                        root.selectedVideoDuration > 0

                                                    width: 3
                                                    height:
                                                        parent.height

                                                    x:
                                                        root.selectedVideoDuration > 0
                                                            ? (
                                                                root.selectedVideoFrame /
                                                                root.selectedVideoDuration
                                                              ) *
                                                              (parent.width - width)
                                                            : 0

                                                    color:
                                                        root.primary

                                                    QQ.Rectangle {
                                                        anchors.horizontalCenter:
                                                            parent.horizontalCenter

                                                        anchors.top:
                                                            parent.top

                                                        anchors.topMargin: 4

                                                        width: 13
                                                        height: 13
                                                        radius: 7

                                                        color:
                                                            root.primary
                                                    }
                                                }

                                                QQ.MouseArea {
                                                    anchors.fill: parent

                                                    enabled:
                                                        !root.timelineLoading &&
                                                        root.selectedVideoDuration > 0

                                                    cursorShape:
                                                        enabled
                                                            ? Qt.SizeHorCursor
                                                            : Qt.ArrowCursor

                                                    onPressed:
                                                        function(mouse) {
                                                            root.setTimelinePosition(
                                                                mouse.x,
                                                                width
                                                            )
                                                        }

                                                    onPositionChanged:
                                                        function(mouse) {
                                                            if (pressed) {
                                                                root.setTimelinePosition(
                                                                    mouse.x,
                                                                    width
                                                                )
                                                            }
                                                        }
                                                }
                                            }

                                            Layouts.RowLayout {
                                                Layouts.Layout.fillWidth: true

                                                Controls.Label {
                                                    text: "00:00"
                                                    color:
                                                        root.textSurfaceVariant
                                                    font.pixelSize: 10
                                                }

                                                QQ.Item {
                                                    Layouts.Layout.fillWidth: true
                                                }

                                                Controls.Label {
                                                    text:
                                                        "Theme frame  " +
                                                        root.formatTime(
                                                            root.selectedVideoFrame
                                                        )

                                                    color:
                                                        root.primary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                QQ.Item {
                                                    Layouts.Layout.fillWidth: true
                                                }

                                                Controls.Label {
                                                    text:
                                                        root.formatTime(
                                                            root.selectedVideoDuration
                                                        )

                                                    color:
                                                        root.textSurfaceVariant
                                                    font.pixelSize: 10
                                                }

                                                Controls.Button {
                                                    text: "Use video"

                                                    enabled:
                                                        !root.timelineLoading &&
                                                        root.selectedVideoPath.length > 0

                                                    palette.buttonText:
                                                        root.primary

                                                    onClicked:
                                                        root.commitVideo()
                                                }
                                            }
                                        }
                                    }

                                    Controls.ScrollView {
                                        Layouts.Layout.fillWidth: true
                                        Layouts.Layout.fillHeight: true

                                        clip: true

                                        QQ.GridView {
                                            id: wallpaperGrid

                                            cellWidth: 160
                                            cellHeight: 105

                                            model:
                                                root.pickerItems()

                                            delegate: QQ.Item {
                                                required property var modelData

                                                width:
                                                    wallpaperGrid.cellWidth

                                                height:
                                                    wallpaperGrid.cellHeight

                                                ClippingRectangle {
                                                    anchors.fill: parent
                                                    anchors.margins: 5

                                                    radius: 10

                                                    opacity:
                                                        root.pickingDefault ||
                                                        root.selectedWorkspace > 0
                                                            ? 1
                                                            : 0.55

                                                    color:
                                                        root.surfaceContainerHigh

                                                    QQ.Image {
                                                        anchors.fill: parent

                                                        visible:
                                                            modelData.type !== "random" &&
                                                            modelData.thumbnail &&
                                                            modelData.thumbnail.length > 0

                                                        source:
                                                            visible
                                                                ? root.fileUrl(
                                                                    modelData.thumbnail
                                                                )
                                                                : ""

                                                        fillMode:
                                                            QQ.Image.PreserveAspectCrop

                                                        asynchronous: true
                                                        smooth: true
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.fill: parent

                                                        visible:
                                                            modelData.type === "random"

                                                        color:
                                                            root.primaryContainer

                                                        Layouts.ColumnLayout {
                                                            anchors.centerIn: parent
                                                            spacing: 6

                                                            QQ.Rectangle {
                                                                Layouts.Layout.alignment:
                                                                    Qt.AlignHCenter

                                                                width: 42
                                                                height: 42
                                                                radius: 9

                                                                color:
                                                                    root.textPrimaryContainer

                                                                QQ.Repeater {
                                                                    model: [
                                                                        [9, 9],
                                                                        [27, 9],
                                                                        [18, 18],
                                                                        [9, 27],
                                                                        [27, 27]
                                                                    ]

                                                                    delegate: QQ.Rectangle {
                                                                        required property var modelData

                                                                        width: 6
                                                                        height: 6
                                                                        radius: 3
                                                                        x: modelData[0]
                                                                        y: modelData[1]

                                                                        color:
                                                                            root.primaryContainer
                                                                    }
                                                                }
                                                            }

                                                            Controls.Label {
                                                                Layouts.Layout.alignment:
                                                                    Qt.AlignHCenter

                                                                text: "Random"

                                                                color:
                                                                    root.textPrimaryContainer

                                                                font.bold: true
                                                                font.pixelSize: 11
                                                            }
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.centerIn: parent

                                                        visible:
                                                            modelData.type === "video" &&
                                                            (!modelData.thumbnail ||
                                                             modelData.thumbnail.length === 0)

                                                        width: 44
                                                        height: 44
                                                        radius: 22

                                                        color:
                                                            root.primaryContainer

                                                        Controls.Label {
                                                            anchors.centerIn: parent
                                                            text: "▶"
                                                            color:
                                                                root.textPrimaryContainer
                                                            font.pixelSize: 17
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.top: parent.top
                                                        anchors.left: parent.left
                                                        anchors.margins: 7

                                                        visible:
                                                            modelData.type === "video"

                                                        width: 24
                                                        height: 24
                                                        radius: 12

                                                        color:
                                                            Qt.rgba(
                                                                0,
                                                                0,
                                                                0,
                                                                0.62
                                                            )

                                                        Controls.Label {
                                                            anchors.centerIn: parent
                                                            text: "▶"
                                                            color: "white"
                                                            font.pixelSize: 10
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.bottom: parent.bottom

                                                        visible:
                                                            modelData.type !== "random"

                                                        height: 27

                                                        color:
                                                            Qt.rgba(
                                                                0,
                                                                0,
                                                                0,
                                                                0.60
                                                            )

                                                        Controls.Label {
                                                            anchors.fill: parent

                                                            anchors.leftMargin: 7
                                                            anchors.rightMargin: 7

                                                            text:
                                                                root.basename(
                                                                    modelData.path
                                                                )

                                                            color: "white"
                                                            font.pixelSize: 10

                                                            elide:
                                                                QQ.Text.ElideMiddle

                                                            verticalAlignment:
                                                                Qt.AlignVCenter
                                                        }
                                                    }

                                                    QQ.MouseArea {
                                                        anchors.fill: parent

                                                        enabled:
                                                            root.pickingDefault ||
                                                            root.selectedWorkspace > 0

                                                        cursorShape:
                                                            enabled
                                                                ? Qt.PointingHandCursor
                                                                : Qt.ArrowCursor

                                                        onClicked:
                                                            root.handlePickerItem(
                                                                modelData
                                                            )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
