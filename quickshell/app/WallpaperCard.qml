import QtQuick as QQ
import QtQuick.Controls as Controls

import Quickshell.Widgets

ClippingRectangle {
    id: card

    required property string title
    required property string preview
    required property bool video
    required property bool random
    required property bool current
    required property bool removable

    required property var backgroundColor
    required property var primaryColor
    required property var primaryContainerColor
    required property var textPrimaryContainerColor

    property bool compact: false

    signal editRequested()
    signal removeRequested()

    radius: compact ? 12 : 16
    color: backgroundColor
    border.width: current ? 2 : 0
    border.color: primaryColor

    QQ.Image {
        anchors.fill: parent
        visible: card.preview.length > 0
        source: visible ? card.preview : ""
        fillMode: QQ.Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    QQ.Rectangle {
        anchors.fill: parent
        visible: card.random
        color: card.primaryContainerColor

        QQ.Rectangle {
            anchors.centerIn: parent
            width: card.compact ? 42 : 54
            height: width
            radius: card.compact ? 9 : 12
            color: card.textPrimaryContainerColor

            QQ.Repeater {
                model: card.compact
                    ? [[9, 9], [27, 9], [18, 18], [9, 27], [27, 27]]
                    : [[12, 12], [36, 12], [24, 24], [12, 36], [36, 36]]

                delegate: QQ.Rectangle {
                    required property var modelData

                    width: card.compact ? 6 : 7
                    height: width
                    radius: width / 2
                    x: modelData[0]
                    y: modelData[1]
                    color: card.primaryContainerColor
                }
            }
        }
    }

    QQ.Rectangle {
        anchors.centerIn: parent
        visible: card.video && card.preview.length === 0
        width: card.compact ? 46 : 64
        height: width
        radius: width / 2
        color: card.primaryContainerColor

        Controls.Label {
            anchors.centerIn: parent
            text: "▶"
            color: card.textPrimaryContainerColor
            font.pixelSize: card.compact ? 18 : 24
        }
    }

    QQ.Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: card.compact ? 7 : 10
        visible: card.video
        width: card.compact ? 24 : 56
        height: 24
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.62)

        Controls.Label {
            anchors.centerIn: parent
            text: card.compact ? "▶" : "▶ VIDEO"
            color: "white"
            font.pixelSize: card.compact ? 10 : 9
            font.bold: true
        }
    }

    QQ.HoverHandler {
        id: hover
    }

    QQ.Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: card.compact ? 36 : 52
        visible: hover.hovered
        color: Qt.rgba(0, 0, 0, card.compact ? 0.34 : 0.26)

        QQ.Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: card.compact ? parent.left : undefined
            anchors.leftMargin: card.compact ? 12 : 0
            anchors.horizontalCenter: card.compact ? undefined : parent.horizontalCenter
            width: card.compact ? 38 : 42
            height: width
            radius: width / 2
            color: card.primaryContainerColor

            Controls.Label {
                anchors.centerIn: parent
                text: "✎"
                color: card.textPrimaryContainerColor
                font.pixelSize: card.compact ? 19 : 21
                font.bold: true
            }

            QQ.MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.editRequested()
            }
        }

        QQ.Rectangle {
            visible: card.removable
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: width
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.34)

            QQ.Item {
                anchors.centerIn: parent
                width: 18
                height: 20

                readonly property var trashRed: "#ef4444"

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
                onClicked: card.removeRequested()
            }
        }
    }

    QQ.Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: card.compact ? 36 : 52
        color: Qt.rgba(0, 0, 0, 0.63)

        Controls.Label {
            anchors.fill: parent
            anchors.leftMargin: card.compact ? 9 : 15
            anchors.rightMargin: card.compact ? 9 : 15
            text: card.title
            color: "white"
            font.pixelSize: card.compact ? 10 : 13
            elide: QQ.Text.ElideMiddle
            verticalAlignment: QQ.Text.AlignVCenter
        }
    }
}
