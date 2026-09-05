import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

QQ.Rectangle {
    id: editor

    required property var state
    required property string videoPath
    required property real duration
    required property real frame
    required property int interval
    required property var frames
    required property bool loading
    required property bool matching

    signal intervalSelected(int interval)
    signal frameSelected(real frame)
    signal accepted()

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0))
        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)
        const remainder = total % 60
        const shortTime =
            minutes.toString().padStart(2, "0") + ":" +
            remainder.toString().padStart(2, "0")
        return hours > 0
            ? hours.toString().padStart(2, "0") + ":" + shortTime
            : shortTime
    }

    radius: Tokens.rounding.medium
    color: editor.state.surfaceContainerLow
    border.width: 1
    border.color: editor.state.outlineVariant

    Layouts.ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Layouts.RowLayout {
            Layouts.Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: editor.state.basename(editor.videoPath)
                color: editor.state.textSurface
                font: Tokens.font.label.medium
                elide: QQ.Text.ElideMiddle
            }

            Controls.Label {
                text: editor.formatTime(editor.duration)
                color: editor.state.textSurfaceVariant
                font: Tokens.font.label.small
            }

            Controls.Label {
                text: "Frames every"
                color: editor.state.textSurfaceVariant
                font: Tokens.font.label.small
            }

            Controls.ComboBox {
                id: intervalCombo

                enabled: !editor.loading && !editor.matching
                Layouts.Layout.preferredWidth: 92
                Layouts.Layout.preferredHeight: 36
                model: [1, 2, 5, 10, 15, 30]
                leftPadding: Tokens.padding.medium
                rightPadding: Tokens.padding.large

                currentIndex: {
                    const index = model.indexOf(editor.interval)
                    return index >= 0 ? index : 2
                }

                contentItem: Controls.Label {
                    text: intervalCombo.displayText
                    color: editor.state.textSurface
                    font: Tokens.font.body.small
                    verticalAlignment: QQ.Text.AlignVCenter
                }

                indicator: Controls.Label {
                    x: intervalCombo.width - width - Tokens.padding.small
                    y: (intervalCombo.height - height) / 2
                    text: "expand_more"
                    color: editor.state.textSurfaceVariant
                    font: Tokens.font.icon.small
                    rotation: intervalCombo.popup.visible ? 180 : 0

                    QQ.Behavior on rotation {
                        QQ.NumberAnimation {
                            duration: Tokens.anim.durations.expressiveFastEffects
                            easing: Tokens.anim.expressiveFastEffects
                        }
                    }
                }

                background: QQ.Rectangle {
                    radius: Tokens.rounding.medium
                    color: intervalCombo.pressed
                        ? editor.state.surfaceContainerLow
                        : editor.state.surfaceContainerHigh
                    border.width: intervalCombo.popup.visible ? 2 : 1
                    border.color: intervalCombo.popup.visible
                        ? editor.state.primary : editor.state.outlineVariant
                }

                delegate: Controls.ItemDelegate {
                    id: intervalOption
                    required property var modelData
                    required property int index
                    width: intervalCombo.popup.width -
                        Tokens.padding.extraSmall * 2
                    height: 34
                    highlighted: intervalCombo.highlightedIndex === index

                    background: QQ.Rectangle {
                        radius: Tokens.rounding.small
                        color: intervalOption.highlighted
                            ? Qt.alpha(editor.state.primary, 0.16)
                            : "transparent"
                    }

                    contentItem: Controls.Label {
                        text: String(intervalOption.modelData)
                        color: editor.state.textSurface
                        font: Tokens.font.body.small
                        verticalAlignment: QQ.Text.AlignVCenter
                    }
                }

                popup: Controls.Popup {
                    y: intervalCombo.height + Tokens.spacing.extraSmall
                    width: intervalCombo.width
                    padding: Tokens.padding.extraSmall
                    implicitHeight:
                        contentItem.implicitHeight + Tokens.padding.extraSmall * 2

                    contentItem: QQ.ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: intervalCombo.popup.visible
                            ? intervalCombo.delegateModel : null
                        currentIndex: intervalCombo.highlightedIndex
                        highlightMoveDuration: 0
                    }

                    background: QQ.Rectangle {
                        radius: Tokens.rounding.medium
                        color: editor.state.surfaceContainerLow
                        border.width: 1
                        border.color: editor.state.outlineVariant
                    }
                }

                onActivated:
                    editor.intervalSelected(Number(model[currentIndex]))
            }

            Controls.Label {
                text: "sec"
                color: editor.state.textSurfaceVariant
                font: Tokens.font.label.small
            }
        }

        QQ.Rectangle {
            id: timeline

            Layouts.Layout.fillWidth: true
            Layouts.Layout.preferredHeight: 86
            radius: Tokens.rounding.small
            clip: true
            color: editor.state.surfaceContainerHigh

            QQ.Repeater {
                model: editor.frames

                delegate: QQ.Image {
                    required property var modelData
                    required property int index
                    width: timeline.width / Math.max(1, editor.frames.length)
                    height: timeline.height
                    x: index * width
                    source: editor.state.fileUrl(modelData.path)
                    fillMode: QQ.Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            Controls.Slider {
                id: timelineSlider

                anchors.fill: parent
                enabled:
                    !editor.loading && !editor.matching && editor.duration > 0
                from: 0
                to: Math.max(0, editor.duration)
                value: Math.min(editor.frame, to)
                live: true
                background: QQ.Item {}

                handle: QQ.Rectangle {
                    x: timelineSlider.leftPadding +
                       timelineSlider.visualPosition *
                       (timelineSlider.availableWidth - width)
                    y: 0
                    width: 3
                    height: parent.height
                    color: editor.state.primary

                    QQ.Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Tokens.padding.extraSmall
                        width: 13
                        height: 13
                        radius: height / 2 * Math.min(1, Tokens.rounding.scale)
                        color: editor.state.primary
                    }
                }

                onMoved: editor.frameSelected(value)
            }

            QQ.Rectangle {
                anchors.fill: parent
                visible: editor.loading
                color: Qt.alpha(editor.state.scrim, 0.42)

                Controls.Label {
                    anchors.centerIn: parent
                    text: "Generating frame track…"
                    color: "white"
                    font: Tokens.font.label.small
                }
            }
        }

        Layouts.RowLayout {
            Layouts.Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Controls.Label {
                text: "00:00"
                color: editor.state.textSurfaceVariant
                font: Tokens.font.label.small
            }

            QQ.Item { Layouts.Layout.fillWidth: true }

            Controls.Label {
                text: "Theme frame  " + editor.formatTime(editor.frame)
                color: editor.state.primary
                font: Tokens.font.label.medium
            }

            QQ.Item { Layouts.Layout.fillWidth: true }

            Controls.Label {
                text: editor.formatTime(editor.duration)
                color: editor.state.textSurfaceVariant
                font: Tokens.font.label.small
            }

            Controls.Button {
                id: useVideoButton

                text: "Use video"
                hoverEnabled: true
                enabled:
                    !editor.loading && !editor.matching &&
                    editor.videoPath.length > 0
                leftPadding: Tokens.padding.large
                rightPadding: Tokens.padding.large
                topPadding: Tokens.padding.small
                bottomPadding: Tokens.padding.small

                contentItem: Controls.Label {
                    text: useVideoButton.text
                    color: useVideoButton.enabled
                        ? editor.state.textPrimary
                        : Qt.alpha(editor.state.textSurface, 0.38)
                    font: Tokens.font.body.small
                    horizontalAlignment: QQ.Text.AlignHCenter
                    verticalAlignment: QQ.Text.AlignVCenter
                }

                background: QQ.Rectangle {
                    radius: useVideoButton.height / 2 *
                        Math.min(1, Tokens.rounding.scale)
                    color: useVideoButton.enabled
                        ? editor.state.primary
                        : Qt.alpha(editor.state.textSurface, 0.10)

                    QQ.Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(
                            editor.state.textPrimary,
                            useVideoButton.down
                                ? 0.10
                                : useVideoButton.hovered ? 0.08 : 0
                        )
                    }
                }

                onClicked: editor.accepted()
            }
        }
    }

    QQ.Rectangle {
        anchors.fill: parent
        visible: editor.matching
        z: 2
        radius: editor.radius
        color: Qt.alpha(editor.state.surfaceContainerLow, 0.94)

        QQ.Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "progress_activity"
                color: editor.state.primary
                font: Tokens.font.icon.large

                QQ.RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: Tokens.anim.durations.expressiveSlowSpatial * 2
                    loops: QQ.Animation.Infinite
                    running: editor.matching
                }
            }

            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Matching your resolution…"
                color: editor.state.textSurface
                font: Tokens.font.label.medium
            }
        }
    }
}
