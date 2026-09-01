import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts

QQ.Rectangle {
    id: editor

    required property string videoPath
    required property real duration
    required property real frame
    required property int interval
    required property var frames
    required property bool loading
    required property bool matching

    required property var surfaceColor
    required property var trackColor
    required property var outlineColor
    required property var textColor
    required property var mutedTextColor
    required property var primaryColor

    signal intervalSelected(int interval)
    signal frameSelected(real frame)
    signal accepted()

    function fileUrl(path) {
        if (!path)
            return ""
        return "file://" + encodeURIComponent(String(path)).replace(/%2F/gi, "/")
    }

    function basename(path) {
        const parts = String(path || "").split("/")
        return parts[parts.length - 1]
    }

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

    radius: 12
    color: surfaceColor
    border.width: 1
    border.color: outlineColor

    Layouts.ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Layouts.RowLayout {
            Layouts.Layout.fillWidth: true

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: editor.basename(editor.videoPath)
                color: editor.textColor
                font.bold: true
                elide: QQ.Text.ElideMiddle
            }

            Controls.Label {
                text: editor.formatTime(editor.duration)
                color: editor.mutedTextColor
                font.pixelSize: 11
            }

            Controls.Label {
                text: "Frames every"
                color: editor.mutedTextColor
                font.pixelSize: 11
            }

            Controls.ComboBox {
                id: intervalCombo

                enabled: !editor.loading && !editor.matching
                Layouts.Layout.preferredWidth: 84
                model: [1, 2, 5, 10, 15, 30]
                currentIndex: {
                    const index = model.indexOf(editor.interval)
                    return index >= 0 ? index : 2
                }
                palette.button: editor.trackColor
                palette.buttonText: editor.textColor
                onActivated:
                    editor.intervalSelected(Number(model[currentIndex]))
            }

            Controls.Label {
                text: "sec"
                color: editor.mutedTextColor
                font.pixelSize: 11
            }
        }

        QQ.Rectangle {
            id: timeline

            Layouts.Layout.fillWidth: true
            Layouts.Layout.preferredHeight: 86
            radius: 9
            clip: true
            color: editor.trackColor

            QQ.Repeater {
                model: editor.frames

                delegate: QQ.Image {
                    required property var modelData
                    required property int index

                    width: timeline.width / Math.max(1, editor.frames.length)
                    height: timeline.height
                    x: index * width
                    source: editor.fileUrl(modelData.path)
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
                    color: editor.primaryColor

                    QQ.Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 13
                        height: 13
                        radius: 7
                        color: editor.primaryColor
                    }
                }

                onMoved: editor.frameSelected(value)
            }

            QQ.Rectangle {
                anchors.fill: parent
                visible: editor.loading
                color: Qt.rgba(0, 0, 0, 0.42)

                Controls.Label {
                    anchors.centerIn: parent
                    text: "Generating frame track…"
                    color: "white"
                    font.pixelSize: 11
                }
            }

        }

        Layouts.RowLayout {
            Layouts.Layout.fillWidth: true

            Controls.Label {
                text: "00:00"
                color: editor.mutedTextColor
                font.pixelSize: 10
            }

            QQ.Item {
                Layouts.Layout.fillWidth: true
            }

            Controls.Label {
                text: "Theme frame  " + editor.formatTime(editor.frame)
                color: editor.primaryColor
                font.pixelSize: 11
                font.bold: true
            }

            QQ.Item {
                Layouts.Layout.fillWidth: true
            }

            Controls.Label {
                text: editor.formatTime(editor.duration)
                color: editor.mutedTextColor
                font.pixelSize: 10
            }

            Controls.Button {
                text: "Use video"
                enabled:
                    !editor.loading && !editor.matching &&
                    editor.videoPath.length > 0
                palette.buttonText: editor.primaryColor
                onClicked: editor.accepted()
            }
        }
    }

    QQ.Rectangle {
        anchors.fill: parent
        visible: editor.matching
        z: 2
        radius: editor.radius
        color: Qt.alpha(editor.surfaceColor, 0.94)

        QQ.Column {
            anchors.centerIn: parent
            spacing: 10

            Controls.BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: editor.matching
                width: 42
                height: 42
            }

            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Matching your resolution…"
                color: editor.textColor
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
