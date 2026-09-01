import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Quickshell
import Caelestia.Config

PopupWindow {
    id: panel

    required property var state
    required property var picker
    required property var mediaService
    visible: picker.open
    implicitWidth: 720
    implicitHeight: picker.videoEditorOpen ? 520 : 330
    color: "transparent"
    grabFocus: false
    anchor.item: picker.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.FlipY
    anchor.margins.bottom: -Tokens.spacing.small

    QQ.Component.onCompleted: picker.panel = panel
    onWidthChanged: picker.position()
    onHeightChanged: picker.position()
    onVisibleChanged: {
        if (visible)
            Qt.callLater(function() { pickerSurface.forceActiveFocus() })
    }
    onClosed: {
        enterAnimation.stop()
        exitAnimation.stop()
        if (picker.target !== null)
            picker.finalizeClose()
    }

    QQ.Connections {
        target: panel.picker
        function onEnterRequested() {
            exitAnimation.stop()
            Qt.callLater(function() { enterAnimation.restart() })
        }
        function onExitRequested() {
            enterAnimation.stop()
            exitAnimation.restart()
        }
    }

    QQ.Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: !panel.picker.videoMatching
        onActivated: panel.picker.close()
    }

    QQ.Item {
        id: pickerSurface
        anchors.fill: parent
        focus: true
        enabled: !panel.picker.closing
        opacity: 1
        property real animatedScale: 1
        property real animatedOffsetY: 0

        Config.screen: panel.screen ? panel.screen.name : ""
        Tokens.screen: panel.screen ? panel.screen.name : ""

        QQ.Keys.onEscapePressed: function(event) {
            if (!panel.picker.videoMatching) {
                panel.picker.close()
                event.accepted = true
            }
        }

        transform: [
            QQ.Translate { y: pickerSurface.animatedOffsetY },
            QQ.Scale {
                origin.x: pickerSurface.width / 2
                origin.y: 0
                xScale: pickerSurface.animatedScale
                yScale: pickerSurface.animatedScale
            }
        ]

        QQ.Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: panel.state.surfaceContainer
            border.width: 1
            border.color: panel.state.outlineVariant

            QQ.Behavior on color {
                QQ.ColorAnimation {
                    duration: Tokens.anim.durations.expressiveSlowEffects
                    easing: Tokens.anim.expressiveSlowEffects
                }
            }
        }

        Layouts.ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            PickerHeader {
                state: panel.state
                picker: panel.picker
                mediaService: panel.mediaService
            }

            Controls.Label {
                visible: !panel.picker.pickingDefault &&
                    panel.picker.selectedWorkspace <= 0
                Layouts.Layout.fillWidth: true
                text: "Select a workspace to enable wallpaper selection."
                color: panel.state.textSurfaceVariant
                font: Tokens.font.label.small
            }

            Controls.Label {
                visible: panel.state.configWriteError.length > 0
                Layouts.Layout.fillWidth: true
                text: panel.state.configWriteError
                color: panel.state.error
                font: Tokens.font.label.small
                wrapMode: QQ.Text.Wrap
            }

            Controls.Label {
                visible: panel.state.mediaError.length > 0
                Layouts.Layout.fillWidth: true
                text: panel.state.mediaError
                color: panel.state.error
                font: Tokens.font.label.small
                wrapMode: QQ.Text.Wrap
            }

            VideoFrameEditor {
                visible: panel.picker.videoEditorOpen
                Layouts.Layout.fillWidth: true
                Layouts.Layout.preferredHeight: 180
                videoPath: panel.picker.selectedVideoPath
                duration: panel.picker.selectedVideoDuration
                frame: panel.picker.selectedVideoFrame
                interval: panel.picker.selectedVideoInterval
                frames: panel.picker.timelineFrames
                loading: panel.picker.timelineLoading
                matching: panel.picker.videoMatching
                surfaceColor: panel.state.surfaceContainerLow
                trackColor: panel.state.surfaceContainerHigh
                outlineColor: panel.state.outlineVariant
                textColor: panel.state.textSurface
                mutedTextColor: panel.state.textSurfaceVariant
                primaryColor: panel.state.primary
                textPrimaryColor: panel.state.textPrimary
                scrimColor: panel.state.scrim
                onIntervalSelected: function(value) {
                    panel.picker.selectedVideoInterval = value
                    panel.mediaService.loadTimeline()
                }
                onFrameSelected: function(value) {
                    panel.picker.selectedVideoFrame = value
                }
                onAccepted: panel.mediaService.commitVideo()
            }

            WallpaperGrid {
                Layouts.Layout.fillWidth: true
                Layouts.Layout.fillHeight: true
                items: panel.state.pickerItems(panel.picker.pickingDefault)
                selectionEnabled: !panel.picker.videoMatching &&
                    (panel.picker.pickingDefault ||
                        panel.picker.selectedWorkspace > 0)
                backgroundColor: panel.state.surfaceContainerHigh
                primaryContainerColor: panel.state.primaryContainer
                textPrimaryContainerColor: panel.state.textPrimaryContainer
                scrimColor: panel.state.scrim
                onItemSelected: function(item) { panel.picker.handleItem(item) }
            }
        }
    }

    QQ.SequentialAnimation {
        id: enterAnimation

        QQ.PropertyAction { target: pickerSurface; property: "opacity"; value: 0 }
        QQ.PropertyAction { target: pickerSurface; property: "animatedScale"; value: 0.96 }
        QQ.PropertyAction {
            target: pickerSurface
            property: "animatedOffsetY"
            value: -Tokens.spacing.small
        }

        QQ.ParallelAnimation {
            QQ.NumberAnimation {
                target: pickerSurface
                property: "opacity"
                to: 1
                duration: Tokens.anim.durations.expressiveDefaultEffects
                easing: Tokens.anim.expressiveDefaultEffects
            }
            QQ.NumberAnimation {
                target: pickerSurface
                property: "animatedScale"
                to: 1
                duration: Tokens.anim.durations.expressiveDefaultSpatial
                easing: Tokens.anim.expressiveDefaultSpatial
            }
            QQ.NumberAnimation {
                target: pickerSurface
                property: "animatedOffsetY"
                to: 0
                duration: Tokens.anim.durations.expressiveDefaultSpatial
                easing: Tokens.anim.expressiveDefaultSpatial
            }
        }
    }

    QQ.SequentialAnimation {
        id: exitAnimation

        QQ.ParallelAnimation {
            QQ.NumberAnimation {
                target: pickerSurface
                property: "opacity"
                to: 0
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
            }
            QQ.NumberAnimation {
                target: pickerSurface
                property: "animatedScale"
                to: 0.97
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
            }
            QQ.NumberAnimation {
                target: pickerSurface
                property: "animatedOffsetY"
                to: -Math.max(1, Math.round(Tokens.spacing.small / 2))
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
            }
        }

        QQ.ScriptAction { script: panel.picker.finalizeClose() }
    }
}
