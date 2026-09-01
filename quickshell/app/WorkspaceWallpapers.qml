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
    property string configPath:
        home + "/.config/caelestia/workspace-wallpapers.json"

    property string schemePath:
        home + "/.local/state/caelestia/scheme.json"

    property string helperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-transfer"

    property string applyPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper"

    property string mediaHelperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-media"

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

    property var pickerTarget: null
    readonly property bool pickerOpen: pickerTarget !== null
    readonly property bool pickingDefault:
        pickerTarget !== null && pickerTarget.kind === "default"
    readonly property int selectedWorkspace:
        pickerTarget !== null && pickerTarget.kind === "workspace"
            ? Number(pickerTarget.id) || -1
            : -1
    readonly property bool editingExistingWorkspace:
        selectedWorkspace > 0 && workspaceHasOverride(selectedWorkspace)
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
        if (!path)
            return ""

        return "file://" + encodeURIComponent(String(path)).replace(/%2F/gi, "/")
    }

    function basename(path) {
        if (!path)
            return ""

        const parts = String(path).split("/")
        return parts[parts.length - 1]
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
        return decodeURIComponent(value.replace(/^file:\/\/(?:localhost)?/, ""))
    }

    function runTransfer(action, fileUrl) {
        if (transferProcess.running || !fileUrl)
            return

        transferStatus = "Working…"
        transferImporting = action.startsWith("import-")
        transferProcess.exec([
            helperPath,
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
        pickerTarget = { "kind": "default" }
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function beginAddWorkspace() {
        pickerTarget = { "kind": "workspace", "id": -1 }
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function editWorkspace(workspace) {
        pickerTarget = { "kind": "workspace", "id": workspace }
        resetVideoEditor()
        rescanMedia()
        scrollPickerIntoView()
    }

    function closePicker() {
        pickerTarget = null
        resetVideoEditor()
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
        if (configWriter.running || transferProcess.running)
            return

        configWriteError = ""
        configWriter.closePickerOnSuccess = true
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

    function commitVideo() {
        if (
            !selectedVideoPath ||
            (!pickingDefault && selectedWorkspace <= 0) ||
            (configWriter.running || transferProcess.running)
        )
            return

        const value = {
            "type": "video",
            "path": selectedVideoPath,
            "themeFrame": Number(selectedVideoFrame.toFixed(3)),
            "interval": selectedVideoInterval
        }

        configWriteError = ""
        configWriter.closePickerOnSuccess = true
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
        if (
            workspace <= 0 ||
            configWriter.running ||
            transferProcess.running
        )
            return

        configWriteError = ""
        configWriter.pendingApplyWorkspace =
            isCurrentWorkspace(workspace)
                ? workspace
                : -1
        configWriter.closePickerOnSuccess = false

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
        property bool closePickerOnSuccess: false

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()

                if (message.length > 0)
                    root.configWriteError = message
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0) {
                configFile.reload()

                if (closePickerOnSuccess)
                    root.closePicker()

                if (pendingApplyWorkspace > 0)
                    root.applyWorkspace(pendingApplyWorkspace)
            }

            pendingApplyWorkspace = -1
            closePickerOnSuccess = false
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
                                            enabled:
                                                !transferProcess.running &&
                                                !configWriter.running
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
                                            enabled:
                                                !transferProcess.running &&
                                                !configWriter.running
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

                            WallpaperCard {
                                Layouts.Layout.fillWidth: true
                                Layouts.Layout.preferredHeight: 180

                                title: root.entryName(root.configData.default)
                                preview: root.fileUrl(
                                    root.entryPreview(root.configData.default)
                                )
                                video: root.isVideoEntry(root.configData.default)
                                random: root.isRandomEntry(root.configData.default)
                                current: false
                                removable: false

                                backgroundColor: root.surfaceContainerHigh
                                primaryColor: root.primary
                                primaryContainerColor: root.primaryContainer
                                textPrimaryContainerColor:
                                    root.textPrimaryContainer

                                onEditRequested: root.openDefaultPicker()
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

                                            WallpaperCard {
                                                Layouts.Layout.fillWidth: true
                                                Layouts.Layout.fillHeight: true

                                                compact: true
                                                title: root.entryName(
                                                    workspaceCard.entry
                                                )
                                                preview: root.fileUrl(
                                                    root.entryPreview(
                                                        workspaceCard.entry
                                                    )
                                                )
                                                video: root.isVideoEntry(
                                                    workspaceCard.entry
                                                )
                                                random: root.isRandomEntry(
                                                    workspaceCard.entry
                                                )
                                                current: root.isCurrentWorkspace(
                                                    workspaceCard.workspace
                                                )
                                                removable: true

                                                backgroundColor:
                                                    root.surfaceContainerHigh
                                                primaryColor: root.primary
                                                primaryContainerColor:
                                                    root.primaryContainer
                                                textPrimaryContainerColor:
                                                    root.textPrimaryContainer

                                                onEditRequested:
                                                    root.editWorkspace(
                                                        workspaceCard.workspace
                                                    )
                                                onRemoveRequested:
                                                    root.clearWorkspace(
                                                        workspaceCard.workspace
                                                    )
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

                                            Layouts.Layout.preferredWidth: 194
                                            Layouts.Layout.preferredHeight: 42
                                            leftPadding: 14
                                            rightPadding: 42
                                            model: root.pickerWorkspaceOptions()

                                            currentIndex: {
                                                if (root.selectedWorkspace <= 0)
                                                    return 0

                                                const index = model.indexOf(
                                                    String(root.selectedWorkspace)
                                                )
                                                return index >= 0 ? index : 0
                                            }

                                            displayText:
                                                currentIndex > 0
                                                    ? "Workspace " + model[currentIndex]
                                                    : model[0]

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
                                                    text: workspaceCombo.displayText
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
                                                root.pickerTarget = {
                                                    "kind": "workspace",
                                                    "id": currentIndex > 0
                                                        ? Number(model[currentIndex])
                                                        : -1
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

                                    VideoFrameEditor {
                                        visible: root.videoEditorOpen
                                        Layouts.Layout.fillWidth: true
                                        Layouts.Layout.preferredHeight: 180

                                        videoPath: root.selectedVideoPath
                                        duration: root.selectedVideoDuration
                                        frame: root.selectedVideoFrame
                                        interval: root.selectedVideoInterval
                                        frames: root.timelineFrames
                                        loading: root.timelineLoading

                                        surfaceColor: root.surfaceContainerLow
                                        trackColor: root.surfaceContainerHigh
                                        outlineColor: root.outlineVariant
                                        textColor: root.textSurface
                                        mutedTextColor: root.textSurfaceVariant
                                        primaryColor: root.primary

                                        onIntervalSelected: function(value) {
                                            root.selectedVideoInterval = value
                                            root.loadTimeline()
                                        }
                                        onFrameSelected: function(value) {
                                            root.selectedVideoFrame = value
                                        }
                                        onAccepted: root.commitVideo()
                                    }

                                    WallpaperGrid {
                                        Layouts.Layout.fillWidth: true
                                        Layouts.Layout.fillHeight: true

                                        items: root.pickerItems()
                                        selectionEnabled:
                                            root.pickingDefault ||
                                            root.selectedWorkspace > 0
                                        backgroundColor:
                                            root.surfaceContainerHigh
                                        primaryContainerColor:
                                            root.primaryContainer
                                        textPrimaryContainerColor:
                                            root.textPrimaryContainer

                                        onItemSelected: function(item) {
                                            root.handlePickerItem(item)
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
