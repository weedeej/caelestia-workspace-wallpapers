import QtQuick as QQ
import QtQuick.Controls as Controls

import Quickshell.Widgets
import "PathUtils.js" as PathUtils

Controls.ScrollView {
    id: grid

    required property var items
    required property bool selectionEnabled
    required property var backgroundColor
    required property var primaryContainerColor
    required property var textPrimaryContainerColor

    signal itemSelected(var item)

    clip: true

    QQ.GridView {
        id: view

        readonly property int columnCount:
            Math.max(1, Math.floor(width / 160))

        cellWidth: width / columnCount
        cellHeight: 105
        model: grid.items

        delegate: QQ.Item {
            required property var modelData

            width: view.cellWidth
            height: view.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 10
                opacity: grid.selectionEnabled ? 1 : 0.55
                color: grid.backgroundColor

                QQ.Image {
                    anchors.fill: parent
                    visible:
                        modelData.type !== "random" &&
                        modelData.thumbnail &&
                        modelData.thumbnail.length > 0
                    source: visible ? PathUtils.fileUrl(modelData.thumbnail) : ""
                    fillMode: QQ.Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                QQ.Rectangle {
                    anchors.fill: parent
                    visible: modelData.type === "random"
                    color: grid.primaryContainerColor

                    QQ.Column {
                        anchors.centerIn: parent
                        spacing: 6

                        QQ.Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 42
                            height: 42
                            radius: 9
                            color: grid.textPrimaryContainerColor

                            QQ.Repeater {
                                model: [[9, 9], [27, 9], [18, 18], [9, 27], [27, 27]]

                                delegate: QQ.Rectangle {
                                    required property var modelData

                                    width: 6
                                    height: 6
                                    radius: 3
                                    x: modelData[0]
                                    y: modelData[1]
                                    color: grid.primaryContainerColor
                                }
                            }
                        }

                        Controls.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Random"
                            color: grid.textPrimaryContainerColor
                            font.bold: true
                            font.pixelSize: 11
                        }
                    }
                }

                QQ.Rectangle {
                    anchors.centerIn: parent
                    visible:
                        modelData.type === "video" &&
                        (!modelData.thumbnail || modelData.thumbnail.length === 0)
                    width: 44
                    height: 44
                    radius: 22
                    color: grid.primaryContainerColor

                    Controls.Label {
                        anchors.centerIn: parent
                        text: "▶"
                        color: grid.textPrimaryContainerColor
                        font.pixelSize: 17
                    }
                }

                QQ.Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 7
                    visible: modelData.type === "video"
                    width: 26
                    height: 26
                    radius: 13
                    color: Qt.rgba(0, 0, 0, 0.62)

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
                    visible: modelData.type !== "random"
                    height: 27
                    color: Qt.rgba(0, 0, 0, 0.60)

                    Controls.Label {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 7
                        text: PathUtils.basename(modelData.path)
                        color: "white"
                        font.pixelSize: 10
                        elide: QQ.Text.ElideMiddle
                        verticalAlignment: QQ.Text.AlignVCenter
                    }
                }

                QQ.MouseArea {
                    anchors.fill: parent
                    enabled: grid.selectionEnabled
                    cursorShape:
                        enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: grid.itemSelected(modelData)
                }
            }
        }
    }
}
