import QtQuick as QQ
import QtQuick.Controls as Controls
import Quickshell.Widgets
import Caelestia.Config

Controls.ScrollView {
    id: grid

    required property var state
    required property var items
    required property bool selectionEnabled

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
                anchors.margins: Tokens.padding.extraSmall
                radius: Tokens.rounding.medium
                opacity: grid.selectionEnabled ? 1 : 0.55
                color: grid.state.surfaceContainerHigh

                QQ.Image {
                    anchors.fill: parent
                    visible:
                        modelData.type !== "random" &&
                        modelData.thumbnail &&
                        modelData.thumbnail.length > 0
                    source: visible
                        ? grid.state.fileUrl(modelData.thumbnail) : ""
                    fillMode: QQ.Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                QQ.Rectangle {
                    anchors.fill: parent
                    visible: modelData.type === "random"
                    color: grid.state.primaryContainer

                    QQ.Column {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        Controls.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "casino"
                            color: grid.state.textPrimaryContainer
                            font: Tokens.font.icon.large
                        }

                        Controls.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Random"
                            color: grid.state.textPrimaryContainer
                            font: Tokens.font.label.small
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
                    radius: height / 2 * Math.min(1, Tokens.rounding.scale)
                    color: grid.state.primaryContainer

                    Controls.Label {
                        anchors.centerIn: parent
                        text: "play_arrow"
                        color: grid.state.textPrimaryContainer
                        font: Tokens.font.icon.medium
                    }
                }

                QQ.Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: Tokens.padding.small
                    visible: modelData.type === "video"
                    width: 26
                    height: 26
                    radius: height / 2 * Math.min(1, Tokens.rounding.scale)
                    color: Qt.alpha(grid.state.scrim, 0.62)

                    Controls.Label {
                        anchors.centerIn: parent
                        text: "play_arrow"
                        color: "white"
                        font: Tokens.font.icon.small
                    }
                }

                QQ.Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: modelData.type !== "random"
                    height: 27
                    color: Qt.alpha(grid.state.scrim, 0.60)

                    Controls.Label {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        text: grid.state.basename(modelData.path)
                        color: "white"
                        font: Tokens.font.label.small
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
