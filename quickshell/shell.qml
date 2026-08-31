import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets

ShellRoot {
    id: root

    // Standalone utility: closing the final FloatingWindow should also
    // terminate `qs -c workspace-wallpapers`.
    QQ.Connections {
        target: Quickshell

        function onLastWindowClosed() {
            Qt.quit()
        }
    }

    property string home: Quickshell.env("HOME")
    property string wallpaperDir: home + "/Pictures/Wallpapers"

    property string configPath:
        home + "/.config/caelestia/workspace-wallpapers.json"

    property string schemePath:
        home + "/.local/state/caelestia/scheme.json"

    property string helperPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper-config"

    property string applyPath:
        home + "/.config/caelestia/scripts/workspace-wallpaper"

    property var configData: ({
        "default": "",
        "workspaces": ({})
    })

    property var schemeData: ({
        "colours": ({})
    })

    property var pendingSchemeData: null
    property bool schemeReady: false

    property var wallpapers: []

    readonly property string randomWallpaperValue:
        "__CAELESTIA_RANDOM__"

    property bool pickerOpen: false
    property bool pickingDefault: false
    property int selectedWorkspace: -1

    // Keep the picker open until the config file confirms the requested value.
    property string pendingWallpaperSelection: ""
    property int pendingSelectionWorkspace: -1
    property bool pendingSelectionDefault: false
    property string configWriteError: ""

    function colour(name, fallback) {
        if (
            schemeData &&
            schemeData.colours &&
            schemeData.colours[name] !== undefined &&
            schemeData.colours[name] !== null
        ) {
            const value = String(
                schemeData.colours[name]
            )

            if (value.length > 0) {
                if (value.startsWith("#"))
                    return value

                return "#" + value
            }
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
        colour("onPrimary", "#30275f")

    readonly property var primaryContainer:
        colour("primaryContainer", "#48406f")

    readonly property var textPrimaryContainer:
        colour("onPrimaryContainer", "#e7deff")

    readonly property var secondaryContainer:
        colour("secondaryContainer", "#464551")

    readonly property var textSecondaryContainer:
        colour("onSecondaryContainer", "#e3e1ef")

    function fileUrl(path) {
        return path
            ? "file://" + encodeURI(path)
            : ""
    }

    function basename(path) {
        if (!path)
            return ""

        const parts = path.split("/")
        return parts[parts.length - 1]
    }

    function isRandomWallpaper(path) {
        return path === randomWallpaperValue
    }

    function displayWallpaperName(path) {
        if (isRandomWallpaper(path))
            return "Random wallpaper"

        return basename(path)
    }

    function pickerItems() {
        if (pickingDefault)
            return wallpapers

        return [randomWallpaperValue].concat(wallpapers)
    }

    function workspaceHasOverride(workspace) {
        if (!configData.workspaces)
            return false

        return configData.workspaces[
            workspace.toString()
        ] !== undefined
    }

    function workspaceWallpaper(workspace) {
        if (!configData.workspaces)
            return ""

        return configData.workspaces[
            workspace.toString()
        ] || ""
    }

    function overrideWorkspaceIds() {
        if (!configData.workspaces)
            return []

        return Object.keys(
            configData.workspaces
        )
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

        return workspaceHasOverride(
            Hyprland.focusedWorkspace.id
        )
    }

    function pickerWorkspaceOptions() {
        const options = ["Select workspace…"]

        for (let workspace = 1; workspace <= 10; workspace++) {
            if (
                !workspaceHasOverride(workspace) ||
                workspace === selectedWorkspace
            ) {
                options.push(String(workspace))
            }
        }

        return options
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

            const targetY = Math.max(
                0,
                pickerPanel.y - 12
            )

            const maxY = Math.max(
                0,
                flick.contentHeight - flick.height
            )

            flick.contentY = Math.min(
                targetY,
                maxY
            )
        })
    }

    function openDefaultPicker() {
        pickingDefault = true
        selectedWorkspace = -1
        pickerOpen = true
        scrollPickerIntoView()
    }

    function beginAddWorkspace() {
        pickingDefault = false
        selectedWorkspace = -1
        pickerOpen = true
        scrollPickerIntoView()
    }

    function editWorkspace(workspace) {
        selectedWorkspace = workspace
        pickingDefault = false
        pickerOpen = true
        scrollPickerIntoView()
    }

    function closePicker() {
        pickerOpen = false
        pickingDefault = false
        selectedWorkspace = -1
        clearPendingSelection()
    }

    function clearPendingSelection() {
        pendingWallpaperSelection = ""
        pendingSelectionWorkspace = -1
        pendingSelectionDefault = false
    }

    function confirmPendingSelection() {
        if (!pendingWallpaperSelection)
            return

        let saved = false

        if (pendingSelectionDefault) {
            saved =
                configData.default === pendingWallpaperSelection
        } else if (
            pendingSelectionWorkspace > 0 &&
            configData.workspaces
        ) {
            saved =
                configData.workspaces[
                    pendingSelectionWorkspace.toString()
                ] === pendingWallpaperSelection
        }

        if (saved) {
            pickerOpen = false
            clearPendingSelection()
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

    function assignWallpaper(path) {
        if (configWriter.running)
            return

        configWriteError = ""

        if (pickingDefault) {
            pendingWallpaperSelection = path
            pendingSelectionDefault = true
            pendingSelectionWorkspace = -1

            configWriter.pendingApplyWorkspace =
                Hyprland.focusedWorkspace &&
                !currentWorkspaceHasOverride()
                    ? Hyprland.focusedWorkspace.id
                    : -1

            configWriter.exec([
                helperPath,
                "set-default",
                path
            ])
        } else if (selectedWorkspace > 0) {
            pendingWallpaperSelection = path
            pendingSelectionDefault = false
            pendingSelectionWorkspace = selectedWorkspace

            configWriter.pendingApplyWorkspace =
                isCurrentWorkspace(
                    selectedWorkspace
                )
                    ? selectedWorkspace
                    : -1

            configWriter.exec([
                helperPath,
                "set",
                selectedWorkspace.toString(),
                path
            ])
        }
    }

    function clearWorkspace(workspace) {
        if (
            workspace <= 0 ||
            configWriter.running
        )
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
                    root.configData =
                        JSON.parse(raw)

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
                    root.applyWorkspace(
                        workspace
                    )
            }
        }
    }

    Process {
        id: applyWallpaper
    }

    Process {
        id: wallpaperScanner

        command: [
            "bash",
            "-lc",
            "find \"" + root.wallpaperDir + "\" " +
            "-maxdepth 1 -type f \\( " +
            "-iname '*.jpg' -o " +
            "-iname '*.jpeg' -o " +
            "-iname '*.png' -o " +
            "-iname '*.webp' " +
            "\\) -print | sort"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text
                    .split("\n")
                    .filter(
                        path => path.length > 0
                    )
            }
        }
    }

    QQ.SequentialAnimation {
        id: themeSwapAnimation

        // Fade the complete utility down before swapping the palette so
        // individual controls never visibly repaint in different schemes.
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
                    root.schemeData = root.pendingSchemeData
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

        implicitWidth: 760
        implicitHeight: 610

        minimumSize:
            Qt.size(560, 460)

        QQ.Rectangle {
            id: themeLayer

            anchors.fill: parent
            color: root.surface

            Layouts.ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Thin draggable strip only.
                QQ.Rectangle {
                    Layouts.Layout.fillWidth: true
                    Layouts.Layout.preferredHeight: 12

                    color:
                        root.surfaceContainer

                    QQ.MouseArea {
                        anchors.fill: parent

                        acceptedButtons:
                            Qt.LeftButton

                        cursorShape:
                            Qt.SizeAllCursor

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

                            anchors.left:
                                parent.left

                            anchors.right:
                                parent.right

                            anchors.top:
                                parent.top

                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            anchors.topMargin: 20

                            spacing: 18

                            Controls.Label {
                                text:
                                    "DEFAULT  (all non-custom use this)"

                                color:
                                    root.textSurfaceVariant

                                font.pixelSize: 12
                                font.bold: true
                            }

                            ClippingRectangle {
                                Layouts.Layout.fillWidth:
                                    true

                                Layouts.Layout.preferredHeight:
                                    180

                                radius: 16

                                color:
                                    root.surfaceContainerHigh

                                QQ.Image {
                                    anchors.fill: parent

                                    source:
                                        root.fileUrl(
                                            root.configData
                                                .default
                                        )

                                    fillMode:
                                        QQ.Image
                                            .PreserveAspectCrop

                                    asynchronous: true
                                    smooth: true
                                }

                                QQ.HoverHandler {
                                    id: defaultHover
                                }

                                QQ.Rectangle {
                                    anchors.fill: parent
                                    anchors.bottomMargin: 52

                                    visible: defaultHover.hovered
                                    color: Qt.rgba(0, 0, 0, 0.26)

                                    QQ.Rectangle {
                                        anchors.centerIn: parent
                                        width: 42
                                        height: 42
                                        radius: 21
                                        color: root.primaryContainer

                                        Controls.Label {
                                            anchors.centerIn: parent
                                            text: "✎"
                                            color: root.textPrimaryContainer
                                            font.pixelSize: 21
                                            font.bold: true
                                        }

                                        QQ.MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openDefaultPicker()
                                        }
                                    }
                                }

                                QQ.Rectangle {
                                    anchors.left:
                                        parent.left

                                    anchors.right:
                                        parent.right

                                    anchors.bottom:
                                        parent.bottom

                                    height: 52

                                    color:
                                        Qt.rgba(
                                            0,
                                            0,
                                            0,
                                            0.62
                                        )

                                    Controls.Label {
                                        anchors.left:
                                            parent.left

                                        anchors.verticalCenter:
                                            parent
                                                .verticalCenter

                                        anchors.leftMargin:
                                            15

                                        width:
                                            parent.width - 120

                                        text:
                                            root.basename(
                                                root.configData
                                                    .default
                                            )

                                        color: "white"

                                        elide:
                                            QQ.Text.ElideMiddle
                                    }

                                }
                            }

                            Layouts.RowLayout {
                                Layouts.Layout.fillWidth:
                                    true

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
                                    Layouts.Layout.fillWidth:
                                        true
                                }
                            }

                            QQ.Flow {
                                Layouts.Layout.fillWidth:
                                    true

                                spacing: 14

                                QQ.Repeater {
                                    model:
                                        root.overrideWorkspaceIds()

                                    delegate: QQ.Item {
                                        id: workspaceCard

                                        required property var modelData

                                        property int workspace:
                                            Number(modelData)

                                        property string wallpaper:
                                            root.workspaceWallpaper(
                                                workspace
                                            )

                                        width: 160
                                        height: 138

                                        Layouts.ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Controls.Label {
                                                text:
                                                    "Workspace " +
                                                    workspaceCard
                                                        .workspace

                                                color:
                                                    root.textSurface

                                                font.pixelSize:
                                                    13

                                                font.bold:
                                                    root.isCurrentWorkspace(
                                                        workspaceCard
                                                            .workspace
                                                    )
                                            }

                                            ClippingRectangle {
                                                Layouts.Layout.fillWidth:
                                                    true

                                                Layouts.Layout.fillHeight:
                                                    true

                                                radius: 12

                                                color:
                                                    root.surfaceContainerHigh

                                                border.width:
                                                    root.isCurrentWorkspace(
                                                        workspaceCard
                                                            .workspace
                                                    )
                                                        ? 2
                                                        : 0

                                                border.color:
                                                    root.primary

                                                QQ.Image {
                                                    anchors.fill: parent

                                                    visible:
                                                        !root.isRandomWallpaper(
                                                            workspaceCard.wallpaper
                                                        )

                                                    source:
                                                        visible
                                                            ? root.fileUrl(
                                                                workspaceCard.wallpaper
                                                            )
                                                            : ""

                                                    fillMode:
                                                        QQ.Image
                                                            .PreserveAspectCrop

                                                    asynchronous: true
                                                    smooth: true
                                                }

                                                QQ.Rectangle {
                                                    anchors.fill: parent

                                                    visible:
                                                        root.isRandomWallpaper(
                                                            workspaceCard.wallpaper
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

                                                QQ.HoverHandler {
                                                    id: workspaceHover
                                                }

                                                // Persistent filename strip, matching the default preview.
                                                QQ.Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom

                                                    height: 36
                                                    color: Qt.rgba(0, 0, 0, 0.63)

                                                    Controls.Label {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.leftMargin: 9
                                                        anchors.rightMargin: 9

                                                        text: root.displayWallpaperName(workspaceCard.wallpaper)
                                                        color: "white"
                                                        font.pixelSize: 10
                                                        elide: QQ.Text.ElideMiddle
                                                    }
                                                }

                                                // Hover action overlay.
                                                QQ.Rectangle {
                                                    anchors.fill: parent
                                                    anchors.bottomMargin: 36

                                                    visible: workspaceHover.hovered
                                                    color: Qt.rgba(0, 0, 0, 0.34)

                                                    QQ.Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.leftMargin: 12

                                                        width: 38
                                                        height: 38
                                                        radius: 19
                                                        color: root.primaryContainer

                                                        Controls.Label {
                                                            anchors.centerIn: parent
                                                            text: "✎"
                                                            color: root.textPrimaryContainer
                                                            font.pixelSize: 19
                                                            font.bold: true
                                                        }

                                                        QQ.MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.editWorkspace(workspaceCard.workspace)
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.rightMargin: 12

                                                        width: 38
                                                        height: 38
                                                        radius: 19

                                                        color: Qt.rgba(
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
                                                                color: parent.trashRed
                                                            }

                                                            QQ.Rectangle {
                                                                x: 2
                                                                y: 3
                                                                width: 14
                                                                height: 3
                                                                radius: 1
                                                                color: parent.trashRed
                                                            }

                                                            QQ.Rectangle {
                                                                x: 6
                                                                y: 0
                                                                width: 6
                                                                height: 4
                                                                radius: 1
                                                                color: parent.trashRed
                                                            }
                                                        }

                                                        QQ.MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.clearWorkspace(workspaceCard.workspace)
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

                                Layouts.Layout.fillWidth:
                                    true

                                Layouts.Layout.preferredHeight:
                                    300

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
                                        Layouts.Layout.fillWidth:
                                            true

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

                                        Controls.ComboBox {
                                            id: workspaceCombo

                                            visible:
                                                !root.pickingDefault

                                            Layouts.Layout.preferredWidth:
                                                180

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

                                            palette.button:
                                                root.surfaceContainerHigh

                                            palette.buttonText:
                                                root.textSurface

                                            palette.highlight:
                                                root.primaryContainer

                                            palette.highlightedText:
                                                root.textPrimaryContainer

                                            onActivated: {
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
                                            Layouts.Layout.fillWidth:
                                                true
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

                                        Layouts.Layout.fillWidth:
                                            true

                                        text:
                                            "Select a workspace to enable wallpaper selection."

                                        color:
                                            root.textSurfaceVariant

                                        font.pixelSize: 11
                                    }

                                    Controls.Label {
                                        visible:
                                            root.configWriteError.length > 0

                                        Layouts.Layout.fillWidth:
                                            true

                                        text:
                                            root.configWriteError

                                        color:
                                            "#ef4444"

                                        font.pixelSize:
                                            11

                                        wrapMode:
                                            QQ.Text.Wrap
                                    }

                                    Controls.ScrollView {
                                        Layouts.Layout.fillWidth:
                                            true

                                        Layouts.Layout.fillHeight:
                                            true

                                        clip: true

                                        QQ.GridView {
                                            id: wallpaperGrid

                                            cellWidth: 160
                                            cellHeight: 105

                                            model:
                                                root.pickerItems()

                                            delegate: QQ.Item {
                                                required property string modelData

                                                width:
                                                    wallpaperGrid
                                                        .cellWidth

                                                height:
                                                    wallpaperGrid
                                                        .cellHeight

                                                ClippingRectangle {
                                                    anchors.fill:
                                                        parent

                                                    anchors.margins:
                                                        5

                                                    radius: 10

                                                    opacity:
                                                        root.pickingDefault ||
                                                        root.selectedWorkspace > 0
                                                            ? 1
                                                            : 0.55

                                                    color:
                                                        root.surfaceContainerHigh

                                                    QQ.Image {
                                                        anchors.fill:
                                                            parent

                                                        visible:
                                                            !root.isRandomWallpaper(
                                                                modelData
                                                            )

                                                        source:
                                                            visible
                                                                ? root.fileUrl(
                                                                    modelData
                                                                )
                                                                : ""

                                                        fillMode:
                                                            QQ.Image
                                                                .PreserveAspectCrop

                                                        asynchronous:
                                                            true

                                                        smooth:
                                                            true
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.fill:
                                                            parent

                                                        visible:
                                                            root.isRandomWallpaper(
                                                                modelData
                                                            )

                                                        color:
                                                            root.primaryContainer

                                                        Layouts.ColumnLayout {
                                                            anchors.centerIn:
                                                                parent

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

                                                                text:
                                                                    "Random"

                                                                color:
                                                                    root.textPrimaryContainer

                                                                font.bold:
                                                                    true

                                                                font.pixelSize:
                                                                    11
                                                            }
                                                        }
                                                    }

                                                    QQ.Rectangle {
                                                        anchors.left:
                                                            parent.left

                                                        anchors.right:
                                                            parent.right

                                                        anchors.bottom:
                                                            parent.bottom

                                                        visible:
                                                            !root.isRandomWallpaper(
                                                                modelData
                                                            )

                                                        height: 27

                                                        color:
                                                            Qt.rgba(
                                                                0,
                                                                0,
                                                                0,
                                                                0.60
                                                            )

                                                        Controls.Label {
                                                            anchors.fill:
                                                                parent

                                                            anchors.leftMargin:
                                                                7

                                                            anchors.rightMargin:
                                                                7

                                                            text:
                                                                root.basename(
                                                                    modelData
                                                                )

                                                            color: "white"

                                                            font.pixelSize:
                                                                10

                                                            elide:
                                                                QQ.Text
                                                                    .ElideMiddle

                                                            verticalAlignment:
                                                                Qt.AlignVCenter
                                                        }
                                                    }

                                                    QQ.MouseArea {
                                                        anchors.fill:
                                                            parent

                                                        enabled:
                                                            root.pickingDefault ||
                                                            root.selectedWorkspace > 0

                                                        cursorShape:
                                                            enabled
                                                                ? Qt.PointingHandCursor
                                                                : Qt.ArrowCursor

                                                        onClicked:
                                                            root.assignWallpaper(
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
