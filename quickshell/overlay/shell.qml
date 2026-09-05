import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia.Config

ShellRoot {
    id: root

    readonly property string runtimeDir:
        Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property string position: "center"
    property var schemeData: ({})

    function colour(name, fallback) {
        const value = schemeData?.colours?.[name]
        if (value === undefined || value === null || String(value).length === 0)
            return fallback
        const hex = String(value)
        return hex.startsWith("#") ? hex : "#" + hex
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.schemeData = JSON.parse(text()) || {}
            } catch (error) {
                console.warn("Unable to read Caelestia scheme:", error)
            }
        }
    }

    function show(value) {
        const fields = value.split("\n")
        if (!fields[0])
            return
        number.text = fields[0]
        position = fields[1] || "center"
        fade.restart()
    }

    FileView {
        id: workspaceFile
        path: root.runtimeDir + "/caelestia-workspace-wallpaper-overlay"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.show(text().trim())
    }

    PanelWindow {
        id: overlay

        contentItem.Config.screen: screen ? screen.name : ""
        contentItem.Tokens.screen: screen ? screen.name : ""

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }
        screen: {
            const monitor = Hyprland.focusedMonitor
            return monitor
                ? Quickshell.screens.find(candidate => candidate.name === monitor.name)
                : null
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        Rectangle {
            id: badge
            width: Math.max(height, number.implicitWidth + Tokens.padding.large * 2)
            height: number.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.large
            color: root.colour("surfaceContainer", "#202025")
            border.width: 1
            border.color: root.colour("outlineVariant", "#45464f")
            readonly property int edgeMargin: Tokens.padding.extraLarge * 2
            x: root.position.endsWith("right")
                ? parent.width - width - edgeMargin
                : root.position.endsWith("left")
                    ? edgeMargin : (parent.width - width) / 2
            y: root.position.startsWith("bottom")
                ? parent.height - height - edgeMargin
                : root.position.startsWith("top")
                    ? edgeMargin : (parent.height - height) / 2
            opacity: 0
            Text {
                id: number
                anchors.centerIn: parent
                color: root.colour("onSurface", "#f1f1f4")
                font: Tokens.font.headline.large
            }
        }

        SequentialAnimation {
            id: fade

            NumberAnimation {
                target: badge
                property: "opacity"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }
            PauseAnimation { duration: 500 }
            NumberAnimation {
                target: badge
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.InCubic
            }
            ScriptAction { script: Qt.quit() }
        }
    }
}
